enum TodoStage {
  Todo,
  InProgress,
  Done,
}

extension TodoStageExtension on TodoStage {
  String get displayName {
    switch (this) {
      case TodoStage.Todo:
        return 'To Do';
      case TodoStage.InProgress:
        return 'In Progress';
      case TodoStage.Done:
        return 'Done';
    }
  }

  String get dbValue {
    switch (this) {
      case TodoStage.Todo:
        return 'Todo';
      case TodoStage.InProgress:
        return 'InProgress';
      case TodoStage.Done:
        return 'Done';
    }
  }
}