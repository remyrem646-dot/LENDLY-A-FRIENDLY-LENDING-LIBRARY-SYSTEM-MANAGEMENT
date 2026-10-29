import 'dart:io';

// LENDLY THEME
class Style {
  static const reset = '\x1B[0m';
  static const teal = '\x1B[38;5;80m';
  static const gold = '\x1B[38;5;220m';
  static const white = '\x1B[97m';
  static const gray = '\x1B[90m';
  static const green = '\x1B[92m';
  static const red = '\x1B[91m';
  static const blue = '\x1B[96m';
  static const purple = '\x1B[95m';
}
const int width = 60;

Future<void> clearScreen() async {
  if (Platform.isWindows) {
    final process = await Process.start(
      'cmd',
      ['/c', 'cls'],
      mode: ProcessStartMode.inheritStdio,
    );
    await process.exitCode;
  } else {
    print('\x1B[2J\x1B[H');
  }
}

String center(String text, [int size = width]) {
  if (text.length >= size) return text;
  int left = (size - text.length) ~/ 2;
  return '${' ' * left}$text';
}

void line() =>
    print('${Style.teal}${'=' * width}${Style.reset}');

void divider() =>
    print('${Style.gray}${'-' * width}${Style.reset}');
    
void heading(String title) {
  line();
  message(title, color: Style.gold);
  line();
}

void message(String text, {String color = Style.white}) =>
    print('$color${center(text)}${Style.reset}');

const int menuBlockWidth = 28;

void menuItem(int number, String text, {
  String color = Style.white,
}) {
  int left = (width - menuBlockWidth) ~/ 2;
  String num = number.toString().padLeft(2);
  print('${' ' * left}$color$num. $text${Style.reset}');
}

void statLine(String label, Object value) {
  int left = (width - 30) ~/ 2;
  print(
    '${' ' * left}${Style.white}'
    '${label.padRight(20)}: $value${Style.reset}',
  );
}

void success(String text) =>
    message('[SUCCESS] $text', color: Style.green);

void warning(String text) =>
    message('[NOTICE] $text', color: Style.gold);

// Reusable logging mixin
mixin LoggerMixin {
  void log(String text) =>
      print('${Style.gray}[LENDLY LOG] $text${Style.reset}');
}

// Abstract parent class
abstract class LibraryItem {
  int id;
  String title;
  String author;
  String genre;

  LibraryItem(this.id, this.title, this.author, this.genre);

  void displayDetails();
  bool canBeBorrowed();
}

// Book inherits from LibraryItem
class Book extends LibraryItem {
  bool isBorrowed = false;
  bool isFavorite = false;

  Book(int id, String title, String author, String genre)
      : super(id, title, author, genre);

  @override
  void displayDetails() {
    divider();
    print('${Style.gold}  BOOK #$id${Style.reset}');
    print('  Title : $title');
    print('  Author: $author');
    print('  Genre : $genre');

    String status = isBorrowed ? 'Borrowed' : 'Available';
    String color = isBorrowed ? Style.red : Style.green;
    print('  Status: $color$status${Style.reset}');

    if (isFavorite) {
      print('  Favorite: ${Style.purple}Yes *${Style.reset}');
    }
  }

  @override
  bool canBeBorrowed() => !isBorrowed;
}

// ReferenceBook inherits from Book
class ReferenceBook extends Book {
  ReferenceBook(int id, String title, String author, String genre)
      : super(id, title, author, genre);

  @override
  bool canBeBorrowed() => false;

  @override
  void displayDetails() {
    divider();
    print('${Style.gold}  REFERENCE BOOK #$id${Style.reset}');
    print('  Title : $title');
    print('  Author: $author');
    print('  Genre : $genre');
    print('  Status: ${Style.blue}Library use only${Style.reset}');
  }
}

// Records borrowing transactions
class BorrowingRecord {
  String borrowerName;
  String email;
  String phone;
  Book book;
  DateTime borrowedDate;
  bool returned = false;

  BorrowingRecord(
    this.borrowerName,
    this.email,
    this.phone,
    this.book,
  ) : borrowedDate = DateTime.now();

  void displayRecord() {
    divider();
    print('  Book      : ${book.title}');
    print('  Borrower  : $borrowerName');
    print('  Email     : $email');
    print('  Phone     : $phone');
    print('  Date      : ${borrowedDate.toString().split(' ')[0]}');
    print('  Status    : ${returned ? 'Returned' : 'Borrowed'}');
  }
}

// Library uses the logging mixin
class Library with LoggerMixin {
  List<Book> books = [];
  List<BorrowingRecord> records = [];
  int nextId = 109;

  Library() {
    books.addAll([
      Book(101, 'Alice in Wonderland', 'Lewis Carroll', 'Fantasy'),
      Book(102, 'The Hobbit', 'J.R.R. Tolkien', 'Fantasy'),
      Book(103, 'Dracula', 'Bram Stoker', 'Horror'),
      Book(104, 'Frankenstein', 'Mary Shelley', 'Horror'),
      Book(105, 'Pride and Prejudice', 'Jane Austen', 'Romance'),
      Book(106, 'Sherlock Holmes', 'Arthur Conan Doyle', 'Mystery'),
      Book(107, 'Dune', 'Frank Herbert', 'Science Fiction'),
      ReferenceBook(
        108, 'World Encyclopedia', 'Academic Press', 'Reference',
      ),
    ]);
  }

  void showGenres() {
    var genres = books.map((b) => b.genre).toSet().toList();
    heading('EXPLORE BOOK GENRES');

    for (int i = 0; i < genres.length; i++) {
      menuItem(i + 1, genres[i]);
    }

    int choice = readInt('Choose genre (0 to return): ');
    if (choice == 0) return;

    if (choice < 1 || choice > genres.length) {
      warning('Invalid genre selection.');
      return;
    }

    heading('${genres[choice - 1].toUpperCase()} COLLECTION');
    for (Book book in books.where(
      (b) => b.genre == genres[choice - 1],
    )) {
      book.displayDetails();
    }
    divider();
  }

  void searchBooks() {
    String query = readText('Search title or author: ').toLowerCase();

    if (query.isEmpty) {
      warning('Please enter a search term.');
      return;
    }

    var results = books.where((b) =>
        b.title.toLowerCase().contains(query) ||
        b.author.toLowerCase().contains(query)).toList();

    heading('SEARCH RESULTS');

    if (results.isEmpty) {
      warning('No matching books found.');
    } else {
      for (Book book in results) {
        book.displayDetails();
      }
      message('${results.length} result(s) found.',
          color: Style.teal);
    }
  }

  Book? findBook(int id) {
    for (Book book in books) {
      if (book.id == id) return book;
    }
    return null;
  }

  // Asynchronous borrowing simulation
Future<void> borrowBook() async {
  heading('BORROW A BOOK');

  int id = readInt('Enter book ID: ');
  Book? book = findBook(id);

  if (book == null) {
    warning('Book not found.');
    return;
  }

  if (!book.canBeBorrowed()) {
    warning('This book is unavailable for borrowing.');
    return;
  }

  print('');
  divider();
  message('BORROWER INFORMATION', color: Style.gold);
  divider();

  String name = readText('Full name: ');
  if (name.isEmpty) {
    warning('Full name cannot be empty.');
    return;
  }

  String email = readText('Email address: ');
  if (!email.contains('@') || !email.contains('.')) {
    warning('Please enter a valid email address.');
    return;
  }

  String phone = readText('Phone number: ');
  if (phone.isEmpty) {
    warning('Phone number cannot be empty.');
    return;
  }

  message('Processing your request...', color: Style.blue);
  await Future.delayed(const Duration(seconds: 1));

  book.isBorrowed = true;
  records.add(BorrowingRecord(name, email, phone, book));

  log('${book.title} borrowed by $name.');
  success('Borrowing completed successfully!');
  message('Borrower: $name', color: Style.teal);
  message('Thank you for using LENDLY!');
}

  // Asynchronous return simulation
  Future<void> returnBook() async {
    heading('RETURN A BOOK');
    int id = readInt('Enter book ID: ');
    Book? book = findBook(id);

    if (book == null || !book.isBorrowed) {
      warning('Book not found or not currently borrowed.');
      return;
    }

    message('Processing your return...', color: Style.blue);
    await Future.delayed(const Duration(seconds: 1));

    book.isBorrowed = false;

    for (int i = records.length - 1; i >= 0; i--) {
      if (records[i].book.id == id && !records[i].returned) {
        records[i].returned = true;
        break;
      }
    }

    log('${book.title} returned.');
    success('Book returned successfully!');
  }

void manageFavorite() {
  heading('MANAGE FAVORITES');

  menuItem(1, 'Add to Favorites');
  menuItem(2, 'Remove from Favorites');
  menuItem(0, 'Return to Main Menu');
  divider();

  int action = readInt('Choose an option: ');

  if (action == 0) {
    return;
  }

  if (action != 1 && action != 2) {
    warning('Invalid option. Please choose 0, 1, or 2.');
    return;
  }

  int id = readInt('Enter book ID: ');
  Book? book = findBook(id);

  if (book == null) {
    warning('Book not found.');
    return;
  }

  if (action == 1) {
    if (book.isFavorite) {
      warning('${book.title} is already in your favorites.');
      return;
    }

    book.isFavorite = true;
    success('${book.title} added to favorites!');
  } else {
    if (!book.isFavorite) {
      warning('${book.title} is not in your favorites.');
      return;
    }

    book.isFavorite = false;
    success('${book.title} removed from favorites!');
  }
}

  void showFavorites() {
    heading('YOUR FAVORITE BOOKS');
    var favorites = books.where((b) => b.isFavorite).toList();

    if (favorites.isEmpty) {
      warning('You have no favorite books yet.');
      return;
    }

    for (Book book in favorites) {
      book.displayDetails();
    }
  }

  void showRecords() {
    heading('BORROWING HISTORY');

    if (records.isEmpty) {
      warning('No borrowing records yet.');
      return;
    }

    for (BorrowingRecord record in records) {
      record.displayRecord();
    }
    divider();
  }

  void showStatistics() {
    int borrowed = books.where((b) => b.isBorrowed).length;
    int available = books.where((b) => b.canBeBorrowed()).length;
    int favorites = books.where((b) => b.isFavorite).length;

    heading('LIBRARY STATISTICS');
    statLine('Total books', books.length);
    statLine('Currently borrowed', borrowed);
    statLine('Available to borrow', available);
    statLine('Borrowing records', records.length);
    statLine('Favorite books', favorites);
    divider();
  }

  void addBook() {
    heading('ADD A NEW BOOK');
    String title = readText('Book title: ');
    String author = readText('Author: ');
    String genre = readText('Genre: ');

    if (title.isEmpty || author.isEmpty || genre.isEmpty) {
      warning('All fields are required.');
      return;
    }

    books.add(Book(nextId, title, author, genre));
    log('Added "$title" with ID $nextId.');
    success('Book added successfully. New ID: $nextId');
    nextId++;
  }
}

// Reusable input functions
String readText(String prompt) {
  stdout.write('${Style.gold}$prompt${Style.reset}');
  return stdin.readLineSync()?.trim() ?? '';
}

int readInt(String prompt) {
  while (true) {
    String input = readText(prompt);
    int? number = int.tryParse(input);

    if (number != null) return number;
    warning('Please enter a valid number.');
  }
}

// Main program
Future<void> main() async {
  Library library = Library();
  bool running = true;

  clearScreen();
  print('');
  line();
  message('YOUR NEIGHBORHOOD LIBRARY', color: Style.teal);
  print('${Style.gold}${center('L E N D L Y')}${Style.reset}');
  message('A Friendly Lending Library');
  message('READ  |  BORROW  |  SHARE', color: Style.gray);
  line();

  print('\nPress Enter to open the menu...');
  stdin.readLineSync();

  while (running) {
  await clearScreen();
    print('');
    heading('MAIN MENU');
    menuItem(1, 'Browse Books by Genre');
    menuItem(2, 'Search Books');
    menuItem(3, 'Borrow a Book');
    menuItem(4, 'Return a Book');
    menuItem(5, 'Add / Remove Favorite');
    menuItem(6, 'View Favorite Books');
    menuItem(7, 'View Borrowing History');
    menuItem(8, 'Library Statistics');
    menuItem(9, 'Add a New Book');
    menuItem(10, 'Exit', color: Style.red);
    divider();

    try {
      int choice = readInt('Choose an option: ');

      switch (choice) {
        case 1:
          library.showGenres();
          break;
        case 2:
          library.searchBooks();
          break;
        case 3:
          await library.borrowBook();
          break;
        case 4:
          await library.returnBook();
          break;
        case 5:
          library.manageFavorite();
          break;
        case 6:
          library.showFavorites();
          break;
        case 7:
          library.showRecords();
          break;
        case 8:
          library.showStatistics();
          break;
        case 9:
          library.addBook();
          break;
        case 10:
          running = false;
          clearScreen();
          line();
          message('Thank you for visiting LENDLY!',
              color: Style.gold);
          message('Happy reading!', color: Style.teal);
          line();
          break;
        default:
          warning('Choose an option from 1 to 10.');
      }
    } catch (e) {
      warning('An unexpected error occurred: $e');
    }

    if (running) {
    print('');
    print('Press Enter to return to the main menu...');
    stdin.readLineSync();
  }
}
}