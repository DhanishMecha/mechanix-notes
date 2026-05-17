import 'package:equatable/equatable.dart';
import 'package:mechanix_notes/core/utils/enums.dart';

class TimeGroup extends Equatable {
  final TimeCategory category;
  final String? customLabel;

  const TimeGroup(this.category, [this.customLabel]);

  @override
  List<Object?> get props => [category, customLabel];
}