//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import device_info_plus
import flutter_secure_storage_macos
import local_auth_darwin
import package_info_plus
import passkeys_darwin
import path_provider_foundation

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  DeviceInfoPlusMacosPlugin.register(with: registry.registrar(forPlugin: "DeviceInfoPlusMacosPlugin"))
  FlutterSecureStoragePlugin.register(with: registry.registrar(forPlugin: "FlutterSecureStoragePlugin"))
  LocalAuthPlugin.register(with: registry.registrar(forPlugin: "LocalAuthPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  PasskeysPlugin.register(with: registry.registrar(forPlugin: "PasskeysPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
}
