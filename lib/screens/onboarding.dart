import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:proyecto/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class Onboarding extends StatefulWidget {
  final double screenHeight;

  const Onboarding({Key? key, required this.screenHeight}) : super(key: key);

  @override
  _OnboardingState createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Widget> _buildPages() {
    return [
      _buildPage(
        title: "Bienvenido a SocialLynx",
        description: "Conéctate con tus estudiantes y colegas en SocialLynx.",
        lottieAsset: "lib/assets/boy1.json",
        backgroundColor: Colors.blue,
      ),
      _buildPage(
        title: "Mantente Informado",
        description:
            "Recibe las últimas actualizaciones y anuncios en tu feed.",
        lottieAsset: "lib/assets/girl1.json",
        backgroundColor: Colors.green,
      ),
      _buildPage(
        title: "Colabora Fácilmente",
        description: "Comparte recursos y colabora en proyectos sin esfuerzo.",
        lottieAsset: "lib/assets/study.json",
        backgroundColor: Colors.orange,
      ),
    ];
  }

  Widget _buildPage({
    required String title,
    required String description,
    required String lottieAsset,
    required Color backgroundColor,
  }) {
    return Container(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(lottieAsset, height: widget.screenHeight * 0.4),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.raleway(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: _buildPages(),
      ),
      bottomSheet: _currentPage == _buildPages().length - 1
          ? TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: Text(
                "Comenzar",
                style: GoogleFonts.raleway(color: Colors.blue, fontSize: 20),
              ),
            )
          : Container(
              height: 60,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _buildPages().length,
                  (index) => _buildDot(index, context),
                ),
              ),
            ),
    );
  }

  Widget _buildDot(int index, BuildContext context) {
    return Container(
      height: 10,
      width: 10,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.white : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}
