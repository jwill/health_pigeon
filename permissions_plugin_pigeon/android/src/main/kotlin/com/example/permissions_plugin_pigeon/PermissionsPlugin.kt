package com.example.permissions_plugin_pigeon

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class PermissionsPlugin : FlutterPlugin, ActivityAware, PermissionsApi {
  private var context: Context? = null
  private var activity: Activity? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    PermissionsApiRegistrar().register(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivity() {
    PermissionsApiRegistrar().register(null)
    activity = null
  }

  override fun getPlatformVersion(): String {
    return "Android ${Build.VERSION.RELEASE}"
  }

  override fun checkPermission(permission: String): Boolean {
    val ctx = activity ?: context ?: return false
    return ContextCompat.checkSelfPermission(ctx, permission) == PackageManager.PERMISSION_GRANTED
  }

  override fun shouldShowRequestPermissionRationale(permission: String): Boolean {
    val act = activity ?: return false
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      act.shouldShowRequestPermissionRationale(permission)
    } else {
      false
    }
  }

  override fun requestPermission(permission: String) {
    activity?.let {
      ActivityCompat.requestPermissions(it, arrayOf(permission), 0)
    }
  }

  override fun requestPermissions(permissions: List<String>) {
    activity?.let {
      ActivityCompat.requestPermissions(it, permissions.toTypedArray(), 0)
    }
  }

  override fun checkAndRequestPermission(permission: String): Long {
    val act = activity ?: return 0L
    return if (ContextCompat.checkSelfPermission(act, permission) == PackageManager.PERMISSION_GRANTED) {
      1L // Granted
    } else if (shouldShowRequestPermissionRationale(permission)) {
      -2L // Should show rationale
    } else {
      ActivityCompat.requestPermissions(act, arrayOf(permission), 0)
      0L // Requested
    }
  }

  override fun openAppSettings(): Boolean {
    val ctx = activity ?: context ?: return false
    return try {
      val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
        data = Uri.fromParts("package", ctx.packageName, null)
        if (activity == null) {
          addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
      }
      ctx.startActivity(intent)
      true
    } catch (e: Exception) {
      false
    }
  }
}
