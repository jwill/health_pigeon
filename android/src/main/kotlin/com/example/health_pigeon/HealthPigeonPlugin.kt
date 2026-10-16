package com.example.health_pigeon

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.BloodPressureRecord
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.Instant
import java.time.ZoneOffset

class HealthPigeonPlugin : FlutterPlugin, ActivityAware, HealthConnectApi {
    private var context: Context? = null
    private var activity: Activity? = null
    private var permissionLauncher: androidx.activity.result.ActivityResultLauncher<Set<String>>? = null
    private var permissionContinuation: kotlin.coroutines.Continuation<Unit>? = null

    private val PERMISSIONS = setOf(
        HealthPermission.getReadPermission(BloodPressureRecord::class),
        HealthPermission.getWritePermission(BloodPressureRecord::class)
    )

    // Health Connect Client
    private val healthConnectClient: HealthConnectClient?
        get() = context?.let { HealthConnectClient.getOrCreate(it) }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        val compAct = binding.activity as? androidx.activity.ComponentActivity
        if (compAct != null) {
            val contract = PermissionController.createRequestPermissionResultContract()
            permissionLauncher = compAct.activityResultRegistry.register(
                "health_pigeon_perm_launcher",
                compAct,
                contract
            ) { grantedPermissions ->
                permissionContinuation?.resumeWith(Result.success(Unit))
                permissionContinuation = null
            }
        }
        HealthConnectApiRegistrar().register(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        HealthConnectApiRegistrar().register(null)
        permissionContinuation?.resumeWith(Result.success(Unit))
        permissionContinuation = null
        permissionLauncher?.unregister()
        permissionLauncher = null
        activity = null
    }

    override suspend fun hasPermissions(): Boolean {
        val client = healthConnectClient ?: return false
        return try {
            val granted = client.permissionController.getGrantedPermissions()
            granted.containsAll(PERMISSIONS)
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    override suspend fun requestPermissions() {
        withContext(Dispatchers.Main) {
            val launcher = permissionLauncher ?: return@withContext
            kotlinx.coroutines.suspendCancellableCoroutine<Unit> { cont ->
                permissionContinuation = cont
                cont.invokeOnCancellation {
                    if (permissionContinuation === cont) {
                        permissionContinuation = null
                    }
                }
                launcher.launch(PERMISSIONS)
            }
        }
    }

    override suspend fun openHealthConnectSettings() {
        val act = activity ?: context ?: return
        withContext(Dispatchers.Main) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    val manageIntent = Intent("android.health.connect.action.MANAGE_HEALTH_PERMISSIONS").apply {
                        putExtra(Intent.EXTRA_PACKAGE_NAME, act.packageName)
                        if (activity == null) addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    if (act.packageManager.resolveActivity(manageIntent, PackageManager.MATCH_DEFAULT_ONLY) != null) {
                        act.startActivity(manageIntent)
                        return@withContext
                    }
                }
                val hcIntent = Intent(HealthConnectClient.ACTION_HEALTH_CONNECT_SETTINGS).apply {
                    if (activity == null) addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                if (act.packageManager.resolveActivity(hcIntent, PackageManager.MATCH_DEFAULT_ONLY) != null) {
                    act.startActivity(hcIntent)
                    return@withContext
                }
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", act.packageName, null)
                    if (activity == null) addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                act.startActivity(intent)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override suspend fun readBloodPressure(
        startMillis: Long,
        endMillis: Long
    ): List<BloodPressureRecordPigeon> {
        val client = healthConnectClient ?: return emptyList()

        return try {
            val request = ReadRecordsRequest(
                recordType = BloodPressureRecord::class,
                timeRangeFilter = TimeRangeFilter.between(
                    Instant.ofEpochMilli(startMillis),
                    Instant.ofEpochMilli(endMillis)
                )
            )
            val response = client.readRecords(request)
            response.records.map { record ->
                BloodPressureRecordPigeon(
                    systolic = record.systolic.inMillimetersOfMercury.toLong(),
                    diastolic = record.diastolic.inMillimetersOfMercury.toLong(),
                    dateMillis = record.time.toEpochMilli(),
                    notes = "" // Health connect BP doesn't have a direct string notes field, leaving empty for now
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
            emptyList()
        }
    }

    override suspend fun writeBloodPressure(record: BloodPressureRecordPigeon) {
        val client = healthConnectClient ?: return
        try {
            val bpRecord = BloodPressureRecord(
                systolic = androidx.health.connect.client.units.Pressure.millimetersOfMercury(record.systolic.toDouble()),
                diastolic = androidx.health.connect.client.units.Pressure.millimetersOfMercury(record.diastolic.toDouble()),
                time = Instant.ofEpochMilli(record.dateMillis),
                zoneOffset = ZoneOffset.UTC,
                metadata = Metadata.manualEntry()
            )
            client.insertRecords(listOf(bpRecord))
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}