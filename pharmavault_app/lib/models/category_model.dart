class CategoryModel {
  final int catId;
  final String catName;
  final String? catDescription;

  CategoryModel({
    required this.catId,
    required this.catName,
    this.catDescription,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      catId:          json['cat_id'] as int,
      catName:        json['cat_name'] as String,
      catDescription: json['cat_description'] as String?,
    );
  }
}
