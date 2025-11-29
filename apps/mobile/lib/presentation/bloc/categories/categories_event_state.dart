import 'package:equatable/equatable.dart';
import '../../../core/entities/entities.dart';

// Events
abstract class CategoriesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoriesEvent {}

// States
abstract class CategoriesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  final List<Category> categories;

  CategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class CategoriesError extends CategoriesState {
  final String message;

  CategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}
