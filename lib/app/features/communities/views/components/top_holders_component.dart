import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TopHoldersComponent extends StatelessWidget {
  const TopHoldersComponent({
    required this.holders,
    this.maxVisible = 5,
    this.onViewAllPressed,
    this.onTapHolder,
    this.amountFormatter,
    super.key,
  });

  final List<TopHolder> holders;
  final int maxVisible;
  final VoidCallback? onViewAllPressed;
  final ValueChanged<TopHolder>? onTapHolder;
  final String Function(double amount)? amountFormatter;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    final i18n = context.i18n;

    final visible = holders.take(maxVisible).toList();

    return ColoredBox(
      color: colors.secondaryBackground,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Assets.svg.iconSearchGroups.icon(size: 18.0.s),
                SizedBox(width: 6.0.s),
                Expanded(
                  child: Text(
                    i18n.top_holders_title(holders.length),
                    style: texts.subtitle3.copyWith(color: colors.onTertiaryBackground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onViewAllPressed != null)
                  GestureDetector(
                    onTap: onViewAllPressed,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 4.0.s),
                      child: Text(
                        i18n.core_view_all,
                        style: texts.caption2.copyWith(color: colors.primaryAccent),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 14.0.s),
            Column(
              children: [
                for (var i = 0; i < visible.length; i++)
                  _TopHolderRow(
                    rank: i + 1,
                    holder: visible[i],
                    amountText: _formatAmount(visible[i].position.amount),
                    onTap: onTapHolder,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amountFormatter != null) return amountFormatter!(amount);
    // Default compact formatting, e.g. 10.2M
    return formatDoubleCompact(amount);
  }
}

class _TopHolderRow extends StatelessWidget {
  const _TopHolderRow({
    required this.rank,
    required this.holder,
    required this.amountText,
    this.onTap,
  });

  final int rank;
  final TopHolder holder;
  final String amountText;
  final ValueChanged<TopHolder>? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;

    final position = holder.position;
    final profile = position.holder;
    final handle = profile.name.isNotEmpty ? '@${profile.name}' : '';

    final rightBadge = Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0.s, vertical: 2.0.s),
      decoration: BoxDecoration(
        color: colors.primaryBackground,
        borderRadius: BorderRadius.circular(12.0.s),
      ),
      child: Text(
        '${position.supplyShare.toStringAsFixed(2)}%',
        style: texts.caption2
            .copyWith(color: colors.primaryText, height: 18 / texts.caption2.fontSize!),
      ),
    );

    return InkWell(
      onTap: onTap == null ? null : () => onTap!(holder),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.0.s),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _RankBadge(rank: rank),
                SizedBox(width: 12.0.s),
                _Avatar(url: profile.avatar),
                SizedBox(width: 8.0.s),
                _NameAndAmount(
                  name: profile.display,
                  handle: handle,
                  amountText: amountText,
                ),
              ],
            ),
            rightBadge,
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final isMedal = rank <= 3;
    final bg = isMedal ? colors.primaryBackground : colors.primaryBackground;
    return Container(
      width: 30.0.s,
      height: 30.0.s,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10.0.s)),
      alignment: Alignment.center,
      child: isMedal
          ? _MedalIcon(rank: rank)
          : Text(
              '$rank',
              style: context.theme.appTextThemes.body.copyWith(color: colors.primaryAccent),
            ),
    );
  }
}

class _MedalIcon extends StatelessWidget {
  const _MedalIcon({required this.rank});
  final int rank;
  @override
  Widget build(BuildContext context) {
    return switch (rank) {
      1 => Assets.svg.iconMeme1stplace,
      2 => Assets.svg.iconMeme2ndtplace,
      3 => Assets.svg.iconMeme3rdplace,
      _ => throw UnimplementedError(),
    }
        .icon();
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    return Container(
      width: 30.0.s,
      height: 30.0.s,
      decoration: BoxDecoration(
        color: colors.onTertiaryFill,
        borderRadius: BorderRadius.circular(10.0.s),
      ),
    );
  }
}

class _NameAndAmount extends StatelessWidget {
  const _NameAndAmount({required this.name, required this.handle, required this.amountText});
  final String name;
  final String handle;
  final String amountText;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: texts.subtitle3.copyWith(color: colors.primaryText)),
        SizedBox(height: 2.0.s),
        Text('$handle • $amountText', style: texts.caption.copyWith(color: colors.quaternaryText)),
      ],
    );
  }
}
