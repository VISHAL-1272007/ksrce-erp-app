import 'package:flutter_test/flutter_test.dart';
import 'package:ksrce_erp/src/core/delete_confirmation.dart';

void main() {
  test('buildDeleteConfirmationText normalizes to lowercase + phrase', () {
    expect(buildDeleteConfirmationText('Computer Science'), 'computer science i assure to remove');
    expect(buildDeleteConfirmationText('  Admin User  '), 'admin user i assure to remove');
  });

  test('isDeleteConfirmationValid matches expected text case-insensitively and trim-safe', () {
    expect(
      isDeleteConfirmationValid(
        entityName: 'Computer Science',
        userInput: '  COMPUTER SCIENCE I ASSURE TO REMOVE  ',
      ),
      isTrue,
    );

    expect(
      isDeleteConfirmationValid(
        entityName: 'Computer Science',
        userInput: 'computer science remove',
      ),
      isFalse,
    );
  });
}
