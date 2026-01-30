// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/cashtag/models/cashtag_embed_data.f.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/cashtag/services/cashtag_insertion_service.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/cashtag/text_editor_cashtag_embed_builder.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';

// Processes cashtag embeds and text cashtags bidirectionally based on market cap availability.
// Downgrades embeds without market cap to text, upgrades text cashtags with showMarketCap=true
// when market cap appears.
void processCashtagEmbeds(QuillController controller, WidgetRef ref) {
  try {
    final delta = controller.document.toDelta();
    final downgrades = <({int position, CashtagEmbedData data})>[];
    final upgrades =
        <({int position, String symbolGroup, String externalAddress, double marketCap})>[];

    var currentOffset = 0;
    for (final op in delta.operations) {
      final length = op.length ?? 1;
      final data = op.data;
      final attrs = op.attributes;

      // 1) Cashtag embeds
      if (data is Map && data.containsKey(cashtagEmbedKey)) {
        try {
          final embedMap = data[cashtagEmbedKey];
          if (embedMap is Map) {
            final cashtagData = CashtagEmbedData.fromJson(
              Map<String, dynamic>.from(embedMap),
            );

            final marketCap = ref
                .read(tokenMarketInfoProvider(cashtagData.externalAddress))
                .asData
                ?.value
                ?.marketData
                .marketCap;

            if (marketCap == null) {
              // No market cap - downgrade to text (but keep showMarketCap=true so it can upgrade later)
              downgrades.add((position: currentOffset, data: cashtagData));
            }
          }
        } catch (_) {
          // ignore malformed embeds
        }
      }

      // 2) Text cashtags with attributes
      else if (data is String &&
          attrs != null &&
          attrs.containsKey(CashtagAttribute.attributeKey) &&
          data.startsWith(r'$')) {
        final showMarketCap = attrs[CashtagAttribute.showMarketCapKey] == true;
        if (showMarketCap) {
          final attrVal = attrs[CashtagAttribute.attributeKey];
          final externalAddress =
              (attrVal is String && attrVal.trim().isNotEmpty && attrVal != r'$')
                  ? attrVal.trim()
                  : null;

          if (externalAddress != null) {
            final marketCap = ref
                .read(tokenMarketInfoProvider(externalAddress))
                .asData
                ?.value
                ?.marketData
                .marketCap;

            if (marketCap != null) {
              upgrades.add(
                (
                  position: currentOffset,
                  symbolGroup: data.substring(1),
                  externalAddress: externalAddress,
                  marketCap: marketCap,
                ),
              );
            }
          }
        }
      }

      currentOffset += length;
    }

    // Downgrade embeds without market cap (reverse order to maintain offsets)
    if (downgrades.isNotEmpty) {
      for (final downgrade in downgrades.reversed) {
        try {
          CashtagInsertionService.downgradeCashtagEmbedToText(
            controller,
            downgrade.position,
            downgrade.data,
          );
        } catch (e, stackTrace) {
          Logger.error(
            e,
            stackTrace: stackTrace,
            message: 'Failed to downgrade cashtag embed at position ${downgrade.position}',
          );
        }
      }
    }

    // Upgrade text cashtags when market cap appears (reverse order to maintain offsets)
    if (upgrades.isNotEmpty) {
      for (final upgrade in upgrades.reversed) {
        try {
          final cashtagData = CashtagEmbedData(
            symbolGroup: upgrade.symbolGroup,
            externalAddress: upgrade.externalAddress,
          );
          final cashtagText = r'$' + upgrade.symbolGroup;
          CashtagInsertionService.upgradeCashtagToEmbed(
            controller,
            upgrade.position,
            cashtagText.length,
            cashtagData,
            upgrade.marketCap,
          );
        } catch (e, stackTrace) {
          Logger.error(
            e,
            stackTrace: stackTrace,
            message: 'Failed to upgrade cashtag at position ${upgrade.position}',
          );
        }
      }
    }
  } catch (e, stackTrace) {
    Logger.error(
      e,
      stackTrace: stackTrace,
      message: 'Failed to process cashtag embeds',
    );
  }
}

// Extracts token external addresses from a delta.
// Returns unique list of external addresses found in both cashtag embeds and text cashtags
// where showMarketCap=true and the cashtag attribute stores an externalAddress.
List<String> _extractCashtagExternalAddresses(Delta delta) {
  final externalAddresses = <String>{};

  for (final op in delta.operations) {
    final data = op.data;
    final attrs = op.attributes;

    if (data is Map && data.containsKey(cashtagEmbedKey)) {
      try {
        final embedMap = data[cashtagEmbedKey];
        if (embedMap is Map) {
          final cashtagData = CashtagEmbedData.fromJson(
            Map<String, dynamic>.from(embedMap),
          );
          if (cashtagData.externalAddress.trim().isNotEmpty) {
            externalAddresses.add(cashtagData.externalAddress.trim());
          }
        }
      } catch (_) {
        // ignore
      }
    } else if (data is String &&
        attrs != null &&
        attrs.containsKey(CashtagAttribute.attributeKey)) {
      final showMarketCap = attrs[CashtagAttribute.showMarketCapKey] == true;
      if (!showMarketCap) continue;

      final attrVal = attrs[CashtagAttribute.attributeKey];
      if (attrVal is String) {
        final ext = attrVal.trim();
        if (ext.isNotEmpty && ext != r'$') {
          externalAddresses.add(ext);
        }
      }
    }
  }

  return externalAddresses.toList();
}

// Hook that processes cashtag embeds bidirectionally based on market cap availability.
// Similar to useProcessMentionEmbeds.
void useProcessCashtagEmbeds(
  QuillController? controller,
  WidgetRef ref, {
  bool enabled = true,
}) {
  final cashtagExternalAddresses = useState<List<String>>([]);
  final isProcessing = useRef(false);

  useEffect(
    () {
      if (!enabled || controller == null) return null;

      void updateExternalAddresses() {
        final delta = controller.document.toDelta();
        final newAddrs = _extractCashtagExternalAddresses(delta);
        final newSet = newAddrs.toSet();
        final curSet = cashtagExternalAddresses.value.toSet();

        if (newSet.length != curSet.length || !newSet.containsAll(curSet)) {
          cashtagExternalAddresses.value = newAddrs;
        }
      }

      updateExternalAddresses();

      final sub = controller.document.changes.listen((_) {
        updateExternalAddresses();
      });

      return sub.cancel;
    },
    [controller, enabled],
  );

  // Watch market caps reactively
  final marketCapStates = cashtagExternalAddresses.value
      .map(
        (externalAddress) => ref.watch(
          tokenMarketInfoProvider(externalAddress).select(
            (state) => state.asData?.value?.marketData.marketCap,
          ),
        ),
      )
      .toList();

  useEffect(
    () {
      if (!enabled || controller == null || cashtagExternalAddresses.value.isEmpty) return null;
      if (isProcessing.value) return null;

      isProcessing.value = true;
      try {
        processCashtagEmbeds(controller, ref);
      } finally {
        isProcessing.value = false;
      }

      return null;
    },
    [controller, marketCapStates, enabled],
  );
}
