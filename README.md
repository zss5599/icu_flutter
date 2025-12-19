本工程使用flutter实现了ICU工具（ https://github.com/W-Mai/icu ）的功能。可用于Android和ios

---------------------------------------------------------------

使用很简单：

final _icuConverter = ICUConverter();

// 转换PNG到LVGL

final lvglData = _icuConverter.convertPngToLvgl(pngData);

// 转换LVGL到PNG

final pngData = _icuConverter.convertLvglToPng(lvglData);


![img_v3_02t4_062417ff-629e-4d8b-8d99-b6786ae0418g](https://github.com/user-attachments/assets/8234e51c-889c-4675-9318-cf0e9436c7c5)
