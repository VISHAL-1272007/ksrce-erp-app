String buildDeleteConfirmationText(String entityName) {
  return '${entityName.trim().toLowerCase()} i assure to remove';
}

bool isDeleteConfirmationValid({
  required String entityName,
  required String userInput,
}) {
  return userInput.trim().toLowerCase() == buildDeleteConfirmationText(entityName);
}
