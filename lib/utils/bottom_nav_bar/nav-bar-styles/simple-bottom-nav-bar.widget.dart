import 'package:flutter/material.dart';

import '../models/nav-bar-essentials.model.dart';

class BottomNavSimple extends StatelessWidget {
  final NavBarEssentials? navBarEssentials;

  const BottomNavSimple({
    Key? key,
    this.navBarEssentials = const NavBarEssentials(items: null),
  }) : super(key: key);

  Widget _buildItem(item, bool isSelected, double? height) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Center(
        child: IconTheme(
          data: IconThemeData(
            size: item.iconSize,
            color: isSelected
                ? (item.activeColorSecondary ?? item.activeColorPrimary)
                : item.inactiveColorPrimary ?? item.activeColorPrimary,
          ),
          child: isSelected ? item.icon : item.inactiveIcon ?? item.icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: navBarEssentials!.navBarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: navBarEssentials!.items!.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (item.onPressed != null) {
                    item.onPressed!(navBarEssentials!.selectedScreenBuildContext);
                  } else {
                    navBarEssentials!.onItemSelected!(index);
                  }
                },
                child: _buildItem(
                  item,
                  navBarEssentials!.selectedIndex == index,
                  navBarEssentials!.navBarHeight,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
