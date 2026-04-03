import 'package:flutter/material.dart';

const Color kIvory = Color(0xFFF7F5F2);
const Color kCardCream = Color(0xFFFFFBF7);
const Color kBlush = Color(0xFFE8B4BA);
const Color kGrey = Color(0xFFB0B0B0);
const Color kMutedGrey = Color(0xFF8C8C8C);

class CreateAnalysisProfileScreen extends StatefulWidget {
  const CreateAnalysisProfileScreen({super.key});

  @override
  State<CreateAnalysisProfileScreen> createState() =>
      _CreateAnalysisProfileScreenState();
}

class _CreateAnalysisProfileScreenState
    extends State<CreateAnalysisProfileScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController(text: "+91");
  final _cityController = TextEditingController();
  bool _consent = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final W = MediaQuery.of(context).size.width;
    final H = MediaQuery.of(context).size.height;
    final compactScale = (H / 850.0).clamp(0.78, 1.0).toDouble();
    final horizontalPadding = (W * 0.07).clamp(16.0, 28.0).toDouble();
    final topSpacing = (H * 0.045 * compactScale).clamp(12.0, 40.0).toDouble();
    final betweenLabelHeading = (H * 0.018 * compactScale)
        .clamp(8.0, 18.0)
        .toDouble();
    final betweenHeadingSub = (H * 0.014 * compactScale)
        .clamp(8.0, 16.0)
        .toDouble();
    final betweenSubCard = (H * 0.018 * compactScale)
        .clamp(8.0, 16.0)
        .toDouble();
    final cardPadding = (W * 0.034 * compactScale).clamp(10.0, 14.0).toDouble();
    final cardRadius = (W * 0.05).clamp(14.0, 22.0).toDouble();
    final fieldSpacing = (H * 0.012 * compactScale).clamp(6.0, 12.0).toDouble();
    final labelInputGap = (H * 0.008 * compactScale)
        .clamp(4.0, 10.0)
        .toDouble();
    final inputHeight = (H * 0.045 * compactScale).clamp(32.0, 42.0).toDouble();
    final consentSpacing = (H * 0.014 * compactScale)
        .clamp(6.0, 12.0)
        .toDouble();
    final buttonSpacing = (H * 0.014 * compactScale)
        .clamp(6.0, 12.0)
        .toDouble();
    final buttonHeight = (H * 0.048 * compactScale)
        .clamp(38.0, 46.0)
        .toDouble();
    final checkboxSize = (W * 0.045).clamp(18.0, 22.0).toDouble();

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafe = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: kIvory,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: bottomInset + bottomSafe + 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: topSpacing),
                        Text(
                          "AI FACIAL ANALYSIS",
                          style: TextStyle(
                            fontSize: (W * 0.030 * compactScale)
                                .clamp(10.0, 13.0)
                                .toDouble(),
                            color: kGrey,
                            letterSpacing: 2.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: betweenLabelHeading),
                        Text(
                          "Create Your Analysis Profile",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Serif',
                            fontSize: (W * 0.066 * compactScale)
                                .clamp(24.0, 32.0)
                                .toDouble(),
                            color: Colors.black87,
                            fontWeight: FontWeight.w400,
                            height: 1.18,
                          ),
                        ),
                        SizedBox(height: betweenHeadingSub),
                        Text(
                          "Your personalized report will be securely stored under this profile.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: (W * 0.038 * compactScale)
                                .clamp(12.0, 16.0)
                                .toDouble(),
                            color: kGrey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: betweenSubCard),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: kCardCream,
                            borderRadius: BorderRadius.circular(cardRadius),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 18,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AdaptiveInputField(
                                label: "Full Name",
                                controller: _nameController,
                                keyboardType: TextInputType.name,
                                labelInputGap: labelInputGap,
                                inputHeight: inputHeight,
                              ),
                              SizedBox(height: fieldSpacing),
                              AdaptiveInputField(
                                label: "Mobile Number",
                                controller: _mobileController,
                                keyboardType: TextInputType.phone,
                                labelInputGap: labelInputGap,
                                inputHeight: inputHeight,
                                prefixText: "+91",
                                isPhone: true,
                                microText: "OTP verification required.",
                              ),
                              SizedBox(height: fieldSpacing),
                              AdaptiveInputField(
                                label: "City",
                                controller: _cityController,
                                keyboardType: TextInputType.text,
                                labelInputGap: labelInputGap,
                                inputHeight: inputHeight,
                              ),
                              SizedBox(height: consentSpacing),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: checkboxSize,
                                    height: checkboxSize,
                                    child: Checkbox(
                                      value: _consent,
                                      onChanged: (v) =>
                                          setState(() => _consent = v ?? false),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      side: BorderSide(color: kGrey, width: 1),
                                      activeColor: kBlush,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          "I agree to the ",
                                          style: TextStyle(
                                            fontSize: W * 0.032,
                                            color: kMutedGrey,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {},
                                          child: Text(
                                            "Terms",
                                            style: TextStyle(
                                              fontSize: W * 0.032,
                                              color: kBlush,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          " & ",
                                          style: TextStyle(
                                            fontSize: W * 0.032,
                                            color: kMutedGrey,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {},
                                          child: Text(
                                            "Privacy Policy",
                                            style: TextStyle(
                                              fontSize: W * 0.032,
                                              color: kBlush,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: buttonSpacing),
                              PrimaryCTAButton(
                                text: "Create My Analysis Profile",
                                enabled: _consent,
                                height: buttonHeight,
                                onPressed: _consent ? () {} : null,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: H * 0.04),
                        Center(
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: kMutedGrey,
                              padding: EdgeInsets.zero,
                              minimumSize: Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Already have a profile? Login",
                              style: TextStyle(
                                fontSize: (W * 0.032 * compactScale)
                                    .clamp(11.0, 14.0)
                                    .toDouble(),
                                color: kMutedGrey,
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: (H * 0.02 * compactScale).clamp(8.0, 20.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdaptiveInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final double labelInputGap;
  final double inputHeight;
  final String? prefixText;
  final bool isPhone;
  final String? microText;

  const AdaptiveInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.labelInputGap,
    required this.inputHeight,
    this.prefixText,
    this.isPhone = false,
    this.microText,
  });

  @override
  Widget build(BuildContext context) {
    final W = MediaQuery.of(context).size.width;
    final H = MediaQuery.of(context).size.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: W * 0.032,
            color: kGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: labelInputGap),
        UnderlineTextField(
          controller: controller,
          keyboardType: keyboardType,
          inputHeight: inputHeight,
          prefixText: prefixText,
          isPhone: isPhone,
        ),
        if (microText != null)
          Padding(
            padding: EdgeInsets.only(top: H * 0.008, left: 2),
            child: Text(
              microText!,
              style: TextStyle(
                fontSize: W * 0.028,
                color: kMutedGrey.withOpacity(0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}

class UnderlineTextField extends StatefulWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;
  final double inputHeight;
  final String? prefixText;
  final bool isPhone;

  const UnderlineTextField({
    super.key,
    required this.controller,
    required this.keyboardType,
    required this.inputHeight,
    this.prefixText,
    this.isPhone = false,
  });

  @override
  State<UnderlineTextField> createState() => _UnderlineTextFieldState();
}

class _UnderlineTextFieldState extends State<UnderlineTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animController;
  late Animation<double> _underlineAnim;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _underlineAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final W = MediaQuery.of(context).size.width;
    return Column(
      children: [
        SizedBox(
          height: widget.inputHeight,
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            style: TextStyle(
              fontSize: W * 0.040,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              prefixText: widget.prefixText,
              prefixStyle: TextStyle(
                fontSize: W * 0.040,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            cursorColor: kBlush,
            textInputAction: TextInputAction.next,
            inputFormatters: widget.isPhone
                ? [
                    // Only allow numbers after +91
                  ]
                : null,
          ),
        ),
        AnimatedBuilder(
          animation: _underlineAnim,
          builder: (context, child) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 2,
                width: W * 0.88 * _underlineAnim.value,
                decoration: BoxDecoration(
                  color: _focusNode.hasFocus ? kBlush : kGrey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class PrimaryCTAButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final double height;
  final VoidCallback? onPressed;

  const PrimaryCTAButton({
    super.key,
    required this.text,
    required this.enabled,
    required this.height,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final W = MediaQuery.of(context).size.width;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kBlush, Color(0xFFF3D1D8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: W * 0.045,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
