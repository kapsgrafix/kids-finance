import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import '../widgets/illustrations.dart';
import 'sheets.dart';
import 'shell.dart';

/// "Let's add your little saver" — first run, and adding more kids later.
class AddKidScreen extends StatefulWidget {
  final bool isFirst;
  const AddKidScreen({super.key, this.isFirst = false});

  @override
  State<AddKidScreen> createState() => _AddKidScreenState();
}

class _AddKidScreenState extends State<AddKidScreen> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  Frequency _frequency = Frequency.monthly;
  String _currency = 'INR';

  @override
  void initState() {
    super.initState();
    _name.addListener(_refresh);
    _amount.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  int get _amountValue => int.tryParse(_amount.text) ?? 0;
  bool get _valid => _name.text.trim().isNotEmpty && _amountValue > 0;

  void _submit() {
    if (!_valid) return;
    final state = AppScope.read(context);
    state.addKid(name: _name.text, pocketMoney: _amountValue, frequency: _frequency, currency: _currency);
    if (widget.isFirst) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickCurrency() async {
    final picked = await showChoiceSheet<String>(
      context,
      title: 'Currency',
      value: _currency,
      options: [for (final c in Currency.all) (c.code, '${c.symbol.trim()}  ${c.code}', c.label)],
    );
    if (picked != null) setState(() => _currency = picked);
  }

  @override
  Widget build(BuildContext context) {
    final cur = Currency.of(_currency);
    return Scaffold(
      backgroundColor: TT.bg,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(TT.gutter, 16, TT.gutter, 24),
            children: [
              if (!widget.isFirst) const Align(alignment: Alignment.centerLeft, child: BackCircle()),
              SizedBox(height: widget.isFirst ? 24 : 4),
              Center(child: Illustration(coinJarSvg, width: 150, height: 140)),
              const SizedBox(height: 8),
              Text(
                widget.isFirst ? "Let's add your little saver" : 'Add another little saver',
                textAlign: TextAlign.center,
                style: TT.display(26, height: 1.15),
              ),
              const SizedBox(height: 4),
              Text(
                "Set up your kid's treasury in a minute",
                textAlign: TextAlign.center,
                style: TT.body(14, color: TT.muted),
              ),
              const SizedBox(height: 28),
              const FieldLabel("Kid's name", icon: TTIcons.smile, tint: TT.purpleSoft, iconColor: TT.purple),
              const SizedBox(height: 8),
              SoftField(
                controller: _name,
                hint: 'e.g. Aarav',
                capitalization: TextCapitalization.words,
                action: TextInputAction.next,
                maxLength: 20,
              ),
              const SizedBox(height: 20),
              const FieldLabel('Pocket money frequency', icon: TTIcons.calendar, tint: TT.coralSoft, iconColor: TT.iconCoral),
              const SizedBox(height: 8),
              Segmented<Frequency>(
                options: const [(Frequency.weekly, 'Weekly'), (Frequency.monthly, 'Monthly')],
                value: _frequency,
                onChanged: (f) => setState(() => _frequency = f),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('Currency', icon: TTIcons.globe, tint: TT.skySoft, iconColor: TT.iconSky),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickCurrency,
                        child: Container(
                          width: 112,
                          height: 54,
                          padding: const EdgeInsets.only(left: 16, right: 12),
                          decoration: BoxDecoration(color: TT.skySoft, borderRadius: BorderRadius.circular(TT.rField)),
                          child: Row(children: [
                            Expanded(child: Text('${cur.symbol.trim()} ${cur.code}', style: TT.body(16))),
                            const TTIcon(TTIcons.chevronDown, color: TT.ink, size: 20, strokeWidth: 3),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Amount', icon: TTIcons.coins, tint: TT.goldSoft, iconColor: TT.iconGold),
                        const SizedBox(height: 8),
                        SoftField(controller: _amount, hint: 'e.g. 500', numeric: true, maxLength: 6, action: TextInputAction.done),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(widget.isFirst ? 'Get Started' : 'Add kid',
                  trailingArrow: widget.isFirst, onPressed: _valid ? _submit : null),
              const SizedBox(height: 12),
              Text('You can change these anytime',
                  textAlign: TextAlign.center, style: TT.body(12, color: TT.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
