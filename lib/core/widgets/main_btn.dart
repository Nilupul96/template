import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rive/rive.dart';
import '../app_assets.dart';
import '../app_colors.dart';
import '../helpers/app_logger.dart';

class MainBtn extends StatefulWidget {
  final String lbl;
  final Function onClick;
  final bool isLoading;
  final bool isEnabled;
  final Color? bgColor;
  final String? icon;
  final bool disableSplash;

  const MainBtn(
      {Key? key,
      this.lbl = "",
      this.bgColor,
      required this.onClick,
      this.isLoading = false,
      this.isEnabled = true,
      this.disableSplash = false,
      this.icon})
      : super(key: key);

  @override
  State<MainBtn> createState() => _MainBtnState();
}

class _MainBtnState extends State<MainBtn> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44.h,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor:
                !widget.isEnabled ? AppColors.bgBlue : widget.bgColor,
            elevation: 0.0,
            splashFactory: widget.disableSplash
                ? NoSplash.splashFactory
                : InkRipple.splashFactory,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          onPressed: widget.isEnabled
              ? !widget.isLoading
                  ? () async {
                      await widget.onClick();
                    }
                  : null
              : null,
          child: widget.isLoading
              ? const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : widget.icon != null
                  ? SvgPicture.asset(widget.icon!)
                  : Text(
                      widget.lbl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    )),
    );
  }
}
