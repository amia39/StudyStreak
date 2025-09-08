import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studystreak/flashcard_model.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'theme_model.dart';

class FlashcardTab extends StatefulWidget {
  const FlashcardTab({super.key});

  @override
  State<FlashcardTab> createState() => _FlashcardTabState();
}

class _FlashcardTabState extends State<FlashcardTab> {
  int? selectedCategoryIndex;
  final TextEditingController questionController = TextEditingController();
  final TextEditingController answerController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  File? _tempQuestionImage;
  File? _tempAnswerImage;
  List<Flashcard> cardsToReview = [];
  Map<String, int> cardAttempts = {};
  int correct = 0;
  int total = 0;
  DateTime startTime = DateTime.now();
  DateTime endTime = DateTime.now();
  late final provider = Provider.of<CardState>(context, listen: false);
  GlobalKey<FormState> formKey = GlobalKey();
  String? userAnswer = "";

  @override
  void initState() {
    super.initState();
    provider.loadFromPreferences();
  }

  Future<void> _pickImage(bool isQuestion) async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        if (isQuestion) {
          _tempQuestionImage = File(image.path);
        } else {
          _tempAnswerImage = File(image.path);
        }
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeImage(bool isQuestion) {
    setState(() {
      if (isQuestion) {
        _tempQuestionImage = null;
      } else {
        _tempAnswerImage = null;
      }
    });
  }

  void addFlashcard() {
    if (selectedCategoryIndex == null) return;
    if (questionController.text.isEmpty &&
        answerController.text.isEmpty &&
        _tempQuestionImage == null &&
        _tempAnswerImage == null) {
      return;
    }

    setState(() {
      provider.addFlashcard(
        selectedCategoryIndex!,
        Flashcard(
          question: questionController.text,
          answer: answerController.text,
          questionImagePath: _tempQuestionImage?.path,
          answerImagePath: _tempAnswerImage?.path,
        ),
      );
      questionController.clear();
      answerController.clear();
      _tempQuestionImage = null;
      _tempAnswerImage = null;
    });
  }

  void addCategory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: categoryController,
          decoration: const InputDecoration(labelText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (categoryController.text.isNotEmpty) {
                setState(() {
                  provider.addCategory(
                      FlashcardCategory(name: categoryController.text));
                  categoryController.clear();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
            'Are you sure you want to delete "${provider.categories[index].name}" and all its flashcards?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.removeCategory(index);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void selectCategory(int index) {
    setState(() {
      selectedCategoryIndex = index;
    });
  }

  void goBackToCategories() {
    setState(() {
      selectedCategoryIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    String appTheme = Provider.of<Customization>(context).appTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedCategoryIndex == null
              ? "Flashcards"
              : provider.categories[selectedCategoryIndex!].name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: appTheme == 'light' ? Colors.blue : const Color.fromARGB(255, 7, 31, 43),
        centerTitle: true,
        leading: selectedCategoryIndex != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: goBackToCategories,
              )
            : null,
      ),
      floatingActionButton: selectedCategoryIndex == null
          ? FloatingActionButton(
              onPressed: addCategory,
              backgroundColor: Colors.white,
              child: const Icon(Icons.add, color: Colors.blue),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                if (provider.categories[selectedCategoryIndex ?? 0].flashcards
                    .isNotEmpty) {
                  setState(() {
                    cardsToReview = List.from(provider
                        .categories[selectedCategoryIndex ?? 0].flashcards);
                    cardAttempts = {};
                    correct = 0;
                    total = 0;
                    startTime = DateTime.now();
                  });
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              _reviewTab(selectedCategoryIndex)));
                }
              },
              backgroundColor: Colors.white,
              label: const Text("Study"),
              icon: const Icon(Icons.book, color: Colors.blue),
            ),
      body: Stack(
        children: [
          Positioned.fill(
            child: appTheme == 'light' ? 
            Image.asset(
              'assets/images/flashcards_background.png',
              fit: BoxFit.cover,
            ) : 
            Image.asset(
              'assets/images/darkmode_flashcards.png',
              fit: BoxFit.cover,
            ),
          ),
          selectedCategoryIndex == null
              ? _buildCategoriesList()
              : _buildFlashcardsList(),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    if (provider.categories.isEmpty) {
      return const Center(
        child: Text(
          'No categories yet. Tap + to add one!',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      );
    }

    return Consumer<CardState>(
      builder: (context, values, child) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: values.categories.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(
                values.categories[index].name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${values.categories[index].flashcards.length} cards',
                style: const TextStyle(fontSize: 14),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteCategoryDialog(context, index);
                    },
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => selectCategory(index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlashcardsList() {
    final currentCategory = provider.categories[selectedCategoryIndex!];
    final flashcardKey = GlobalKey<FormState>();

    return Consumer<CardState>(
      builder: (context, values, child) => OrientationBuilder(
        builder: (context, orientation) {
          return Flex(
            direction: orientation == Orientation.portrait
                ? Axis.vertical
                : Axis.horizontal,
            children: [
              // Flashcards List - Full width with delete buttons
              Expanded(
                flex: orientation == Orientation.portrait ? 3 : 1,
                child: currentCategory.flashcards.isEmpty
                    ? const Center(
                        child: Text(
                          'No flashcards yet. Add one below!',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: currentCategory.flashcards.length,
                        itemBuilder: (context, index) {
                          final card = currentCategory.flashcards[index];
                          return Dismissible(
                            key: Key('${card.question}$index'),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete,
                                  color: Colors.white, size: 30),
                            ),
                            confirmDismiss: (direction) async {
                              return await _showDeleteFlashcardDialog(
                                  context, index);
                            },
                            onDismissed: (direction) {
                              provider.removeFlashcard(
                                  selectedCategoryIndex!, index);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        card.isFlipped = !card.isFlipped;
                                      });
                                    },
                                    child: Card(
                                      elevation: 4,
                                      margin: EdgeInsets.zero,
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 200,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: card.isFlipped
                                              ? _buildCardSide(
                                                  card.answer, card.answerImage)
                                              : _buildCardSide(card.question,
                                                  card.questionImage),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        _showDeleteFlashcardDialog(
                                            context, index);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Add Flashcard Form
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    maxWidth: orientation == Orientation.portrait
                        ? double.infinity
                        : MediaQuery.of(context).size.width * 0.4,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: flashcardKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: questionController,
                            decoration: const InputDecoration(
                              labelText: "Question",
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a value.';
                              }
                              for (final card in currentCategory.flashcards) {
                                if (value == card.question) {
                                  return 'Question already exists.';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => _pickImage(true),
                                child: const Text("Add Image"),
                              ),
                              const SizedBox(width: 8),
                              if (_tempQuestionImage != null)
                                ElevatedButton(
                                  onPressed: () => _removeImage(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[200],
                                  ),
                                  child: const Text("Remove"),
                                ),
                            ],
                          ),
                          if (_tempQuestionImage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: SizedBox(
                                height: 100,
                                child: Image.file(_tempQuestionImage!,
                                    fit: BoxFit.contain),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: answerController,
                            decoration: const InputDecoration(
                              labelText: "Answer",
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a value.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => _pickImage(false),
                                child: const Text("Add Image"),
                              ),
                              const SizedBox(width: 8),
                              if (_tempAnswerImage != null)
                                ElevatedButton(
                                  onPressed: () => _removeImage(false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[200],
                                  ),
                                  child: const Text("Remove"),
                                ),
                            ],
                          ),
                          if (_tempAnswerImage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: SizedBox(
                                height: 100,
                                child: Image.file(_tempAnswerImage!,
                                    fit: BoxFit.contain),
                              ),
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (flashcardKey.currentState!.validate()) {
                                addFlashcard();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text("Add Flashcard"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _showDeleteFlashcardDialog(
      BuildContext context, int index) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Flashcard'),
            content:
                const Text('Are you sure you want to delete this flashcard?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  provider.removeFlashcard(selectedCategoryIndex!, index);
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildCardSide(String text, File? image) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (image != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Image.file(image, fit: BoxFit.contain),
              ),
            ),
          if (text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _reviewTab(int? selectedCategory) {
    String appTheme = Provider.of<Customization>(context, listen: false).appTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Study: ${provider.categories[selectedCategoryIndex ?? 0].name}",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: appTheme == 'light' ? Colors.blue : const Color.fromARGB(255, 7, 31, 43),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StatefulBuilder(builder: (context, setNewState) {
          return OrientationBuilder(builder: (context, orientation) {
            if (cardsToReview.isNotEmpty) {
              return Flex(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                direction: orientation == Orientation.portrait
                    ? Axis.vertical
                    : Axis.horizontal,
                children: [
                  Card(
                    elevation: 4,
                    child: SizedBox(
                      height: 200,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          width: orientation == Orientation.portrait
                              ? MediaQuery.of(context).size.width * 0.8
                              : MediaQuery.of(context).size.width * 0.5,
                          child: _buildCardSide(cardsToReview[0].question,
                              cardsToReview[0].questionImage),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Form(
                        key: formKey,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(children: [
                            Container(
                              width: orientation == Orientation.portrait
                                  ? MediaQuery.of(context).size.width
                                  : MediaQuery.of(context).size.width * 0.3,
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: "Answer",
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Provide an answer.';
                                  }
                                  return null;
                                },
                                onSaved: (newValue) {
                                  userAnswer = newValue;
                                  formKey.currentState?.reset();
                                },
                              ),
                            ),
                            ElevatedButton(
                              child: const Text("Submit"),
                              onPressed: () {
                                final state = formKey.currentState;
                                endTime = DateTime.now();
                                if (state!.validate()) {
                                  state.save();
                                  cardAttempts[cardsToReview[0].question] =
                                      (cardAttempts[
                                                  cardsToReview[0].question] ??
                                              0) +
                                          1;

                                  if (userAnswer == cardsToReview[0].answer) {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => AlertDialog(
                                        title: Text("Correct!"),
                                        content: Column(children: [
                                          Flexible(
                                            child: Text(
                                                "The answer was: ${cardsToReview[0].answer}"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => setNewState(() {
                                              cardsToReview.removeAt(0);
                                              correct += 1;
                                              total += 1;
                                              Navigator.of(context).pop();
                                            }),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor:
                                                  const Color.fromARGB(
                                                      255, 255, 255, 255),
                                            ),
                                            child: const Text("OK"),
                                          ),
                                        ]),
                                      ),
                                    );
                                  } else {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => AlertDialog(
                                        title: Text("Incorrect"),
                                        content: Column(children: [
                                          Flexible(
                                            child: Text(
                                                "The answer was: ${cardsToReview[0].answer}"),
                                          ),
                                          Flexible(
                                            child: Text(
                                                "Your answer was: $userAnswer"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => setNewState(() {
                                              final temp = cardsToReview[0];
                                              cardsToReview.removeAt(0);
                                              cardsToReview.add(temp);
                                              total += 1;
                                              Navigator.of(context).pop();
                                            }),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor:
                                                  const Color.fromARGB(
                                                      255, 255, 255, 255),
                                            ),
                                            child: const Text("OK"),
                                          ),
                                        ]),
                                      ),
                                    );
                                  }
                                }
                              },
                            )
                          ]),
                        ),
                      ),
                      Text("Cards remaining: ${cardsToReview.length}"),
                    ],
                  ),
                ],
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge,
                          "All cards reviewed."),
                      SizedBox(height: 15.0),
                      Text(
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                          "Your accuracy was ${((correct / total) * 100).round()}%"),
                      Text(
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                          "Your time was ${endTime.difference(startTime).inSeconds} seconds"),
                      SizedBox(height: 50.0),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    _analysisTab(cardAttempts))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor:
                              const Color.fromARGB(255, 255, 255, 255),
                        ),
                        child: const Text("Analysis"),
                      ),
                      ElevatedButton(
                        onPressed: () => setNewState(() {
                          cardsToReview = List.from(provider
                              .categories[selectedCategoryIndex ?? 0]
                              .flashcards);
                          correct = 0;
                          total = 0;
                          cardAttempts = {};
                          startTime = DateTime.now();
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor:
                              const Color.fromARGB(255, 255, 255, 255),
                        ),
                        child: const Text("Review Again"),
                      ),
                    ],
                  ),
                ),
              );
            }
          });
        }),
      ),
    );
  }

  Widget _analysisTab(Map<String, int> cardAttempts) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Analysis",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Builder(builder: (context) {
        final cardKeys = cardAttempts.keys.toList();
        cardKeys.sort(
            (b, a) => ((cardAttempts[a] ?? 1).compareTo(cardAttempts[b] ?? 1)));
        return CustomScrollView(slivers: <Widget>[
          SliverFixedExtentList(
            itemExtent: 50.0,
            delegate: SliverChildBuilderDelegate(
              childCount: cardKeys.length,
              (BuildContext context, int index) {
                Color getColor(int attempts) {
                  if (attempts == 1) {
                    return const Color.fromARGB(255, 14, 147, 49);
                  } else if (attempts < 3) {
                    return const Color.fromARGB(255, 133, 195, 149);
                  } else if (attempts < 5) {
                    return const Color.fromARGB(255, 215, 133, 133);
                  } else {
                    return const Color.fromARGB(255, 179, 59, 57);
                  }
                }

                Text getText(int attempts) {
                  if (attempts != 1) {
                    return Text('${cardKeys[index]}: $attempts attempts');
                  } else {
                    return Text('${cardKeys[index]}: $attempts attempt');
                  }
                }

                final attempts = cardAttempts[cardKeys[index]] ?? 0;
                return Container(
                  alignment: Alignment.center,
                  color: getColor(attempts),
                  child: getText(attempts),
                );
              },
            ),
          )
        ]);
      }),
    );
  }
}
