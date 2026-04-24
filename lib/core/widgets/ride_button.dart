import 'package:flutter/material.dart';

class RideLinkButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;

  const RideLinkButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap: onPressed,
      child: Flexible(
        child: Container(
          width: MediaQuery.of(context).size.width,
         decoration: BoxDecoration(
            color: isOutlined?Theme.of(context).colorScheme.primary
            :Theme.of(context).colorScheme.surface,
        
          ),
          height: height,
          child: isLoading?CircularProgressIndicator():
          Text(text,style: TextStyle(
            color: isOutlined?Theme.of(context).colorScheme.onPrimary:Theme.of(context).colorScheme.onSurface,
        
          ),)
          ,
        ),
      ),
    );

  }
   
}


