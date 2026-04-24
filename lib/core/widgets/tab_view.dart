import 'package:flutter/material.dart';

class RideTabView extends StatelessWidget {
  const RideTabView({
    super.key,
    required this.count,
    this.isScrollable = false,
    this.tabHeight = 50.0,
    this.hasIcon = false,
    this.colorTab=false,
    this.icons,
    required this.labels,
    required this.selectedTab,
    required this.onClick,
  });

  final int count;
  final bool? isScrollable;
  final bool? colorTab;
  final double? tabHeight;
  final bool? hasIcon;
  final List<IconData>? icons;
  final List<String> labels;
  final int selectedTab;
  final Function(int index) onClick;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      height: tabHeight,
      child: DefaultTabController(
        length: count,
        initialIndex: selectedTab,
        child: isScrollable!
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildTabs(context),
                ),
              )
            : Row(
                children: _buildTabs(context),
              ),
      ),
    );
  }

  List<Widget> _buildTabs(BuildContext context) {
    return List.generate(count, (index) {
      final bool isSelected = index == selectedTab;
      return Expanded(
        flex: isScrollable! ? 0 : 1,
        child: GestureDetector(
          onTap: () => onClick(index),
          child: Container(
            
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: BoxBorder.fromLTRB(
                bottom: BorderSide(
                  width: 2,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                  
                )
              ),
              color:( isSelected && colorTab!)? Theme.of(context).primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(0.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            margin: isScrollable! ? const EdgeInsets.symmetric(horizontal: 4.0) : EdgeInsets.zero,
            child: hasIcon!
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icons![index],
                        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                        size: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    labels[index],
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      );
    });
  }
}