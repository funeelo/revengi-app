package org.revengi.app.arsclib

import com.reandroid.apk.ApkBundle
import com.reandroid.apk.ApkModule
import com.reandroid.app.AndroidManifest
import com.reandroid.arsc.chunk.xml.AndroidManifestBlock
import com.reandroid.arsc.chunk.xml.ResXmlElement
import com.reandroid.arsc.value.ValueType
import org.revengi.app.FlutterLogger
import org.revengi.app.MainActivity.Companion.sendLog
import java.util.regex.Pattern

class Merger {
    fun startMerge(options: Map<String, Any?>?) {
        Thread {
            try {
                sendLog("Searching apk files ...")
                val dir = options?.get("extractedDir")
                val outputFilePath = options?.get("outputFile") as? String
                val validateModules = (options?.get("validateModules") as? Boolean) ?: false
                val resDirName = options?.get("resDirName") as? String
                val validateResDir = (options?.get("validateResDir") as? Boolean) ?: false
                val cleanMeta = (options?.get("cleanMeta") as? Boolean) ?: false
                val extractNativeLibs = options?.get("extractNativeLibs") as? String
                val logger = FlutterLogger()

                val bundle = ApkBundle()

                val dirPath = dir as? String
                val dirFile = if (dirPath != null) java.io.File(dirPath) else null
                val outputFile = if (outputFilePath != null) java.io.File(outputFilePath) else null
                bundle.setAPKLogger(logger)
                bundle.loadApkDirectory(dirFile, true)
                sendLog("Found modules: ${bundle.apkModuleList.size}")
                val mergedModule = bundle.mergeModules(validateModules)
                if (!resDirName.equals("")) {
                    sendLog("Renaming resources root dir: $resDirName")
                    mergedModule.setResourcesRootDir(resDirName)
                }
                if (validateResDir) {
                    sendLog("Validating resources dir ...")
                    mergedModule.validateResourcesDir()
                }
                if (cleanMeta) {
                    sendLog("Clearing META-INF ...")
                    clearMeta(mergedModule)
                }
                sanitizeManifest(mergedModule, logger)
                mergedModule.refreshTable()
                mergedModule.refreshManifest()
                applyExtractNativeLibs(mergedModule, extractNativeLibs)
                sendLog("Writing apk ...")
                mergedModule.writeApk(outputFile)
                mergedModule.close()
                bundle.close()
                if (dirFile != null && dirFile.exists()) {
                    dirFile.deleteRecursively()
                }
                sendLog("Saved to: $outputFile")
                sendLog("Merge task complete", "mergeComplete")
            } catch (e: Exception) {
                sendLog("Error: ${e.message}", "error")
            }
        }.start()
    }

    private fun clearMeta(module: ApkModule) {
        removeSignature(module)
        module.apkSignatureBlock = null
    }

    private fun removeSignature(module: ApkModule) {
        val archive = module.zipEntryMap
        archive.removeIf(Pattern.compile("^META-INF/.+\\.(([MS]F)|(RSA))"))
        archive.remove("stamp-cert-sha256")
    }

    private fun sanitizeManifest(
        apkModule: ApkModule,
        logger: FlutterLogger,
    ) {
        if (!apkModule.hasAndroidManifest()) {
            return
        }
        val manifest = apkModule.androidManifest
        sendLog("Sanitizing manifest ...")

        AndroidManifestHelper.removeAttributeFromManifestById(
            manifest,
            AndroidManifest.ID_requiredSplitTypes,
            logger,
        )
        AndroidManifestHelper.removeAttributeFromManifestById(
            manifest,
            AndroidManifest.ID_splitTypes,
            logger,
        )
        AndroidManifestHelper.removeAttributeFromManifestByName(
            manifest,
            AndroidManifest.NAME_splitTypes,
            logger,
        )

        AndroidManifestHelper.removeAttributeFromManifestByName(
            manifest,
            AndroidManifest.NAME_requiredSplitTypes,
            logger,
        )
        AndroidManifestHelper.removeAttributeFromManifestByName(
            manifest,
            AndroidManifest.NAME_splitTypes,
            logger,
        )
        AndroidManifestHelper.removeAttributeFromManifestAndApplication(
            manifest,
            AndroidManifest.ID_isSplitRequired,
            logger,
            AndroidManifest.NAME_isSplitRequired,
        )
        val application = manifest.applicationElement
        val splitMetaDataElements: List<ResXmlElement> =
            AndroidManifestHelper.listSplitRequired(application)
        var splitsRemoved = false
        for (meta in splitMetaDataElements) {
            if (!splitsRemoved) {
                splitsRemoved = removeSplitsTableEntry(meta, apkModule)
            }
            sendLog(
                (
                    "Removed-element : <" + meta.name + "> name=\"" +
                        AndroidManifestBlock.getAndroidNameValue(meta) + "\""
                ),
            )
            application.remove(meta)
        }
        manifest.refresh()
    }

    private fun removeSplitsTableEntry(
        metaElement: ResXmlElement,
        apkModule: ApkModule,
    ): Boolean {
        val nameAttribute =
            metaElement.searchAttributeByResourceId(AndroidManifest.ID_name)
                ?: return false
        if ("com.android.vending.splits" != nameAttribute.valueAsString) {
            return false
        }
        var valueAttribute =
            metaElement.searchAttributeByResourceId(
                AndroidManifest.ID_value,
            )
        if (valueAttribute == null) {
            valueAttribute =
                metaElement.searchAttributeByResourceId(
                    AndroidManifest.ID_resource,
                )
        }
        if (valueAttribute == null ||
            valueAttribute.valueType != ValueType.REFERENCE
        ) {
            return false
        }
        if (!apkModule.hasTableBlock()) {
            return false
        }
        val tableBlock = apkModule.tableBlock
        val resourceEntry = tableBlock.getResource(valueAttribute.data) ?: return false
        val zipEntryMap = apkModule.zipEntryMap
        for (entry in resourceEntry) {
            if (entry == null) {
                continue
            }
            val resValue = entry.resValue ?: continue
            val path = resValue.valueAsString
            sendLog("Removed-table-entry : $path")
            // Remove file entry
            zipEntryMap.remove(path)
            // It's not safe to destroy entry, resource id might be used in dex code.
            // Better replace it with boolean value.
            entry.isNull = true
            val specTypePair =
                entry.typeBlock
                    .parentSpecTypePair
            specTypePair.removeNullEntries(entry.id)
        }
        return true
    }

    private fun applyExtractNativeLibs(
        apkModule: ApkModule,
        extractNativeLibs: String?,
    ) {
        if (extractNativeLibs != null) {
            val value =
                if ("manifest".equals(extractNativeLibs, ignoreCase = true)) {
                    if (apkModule.hasAndroidManifest()) {
                        apkModule.androidManifest.isExtractNativeLibs
                    } else {
                        null
                    }
                } else if ("true".equals(extractNativeLibs, ignoreCase = true)) {
                    java.lang.Boolean.TRUE
                } else if ("false".equals(extractNativeLibs, ignoreCase = true)) {
                    java.lang.Boolean.FALSE
                } else {
                    null
                }
            sendLog("Applying: extractNativeLibs=$value")
            apkModule.setExtractNativeLibs(value)
        }
    }
}
