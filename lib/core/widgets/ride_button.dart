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
      child: Container(
        width: MediaQuery.of(context).size.width,
       decoration: BoxDecoration(
        border: BoxBorder.all(
          color: foregroundColor??Colors.grey
        ),
         borderRadius: BorderRadius.circular(15),
          color: isOutlined? backgroundColor??Theme.of(context).colorScheme.primary:backgroundColor
        
      
        ),
        height: height,
        child: isLoading?Center(child: CircularProgressIndicator()):
        Center(
          child: Text(text,style: TextStyle(
            fontWeight: FontWeight.w500,
            color: foregroundColor
          ),),
        )
        ,
      ),
    );

  }
   
}


