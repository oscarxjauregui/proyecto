import 'package:flutter/material.dart';
import 'package:proyecto/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _finishOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) =>
            LoginScreen())); // Navega a la pantalla de inicio de sesión
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                // Diapositiva 1
                _buildPage(
                  title: 'Conéctate con tus alumnos y colegas',
                  description:
                      'SocialLynx te permite interactuar con tus estudiantes y otros maestros como nunca antes.',
                ),
                // Diapositiva 2
                _buildPage(
                  title: 'Comparte contenido educativo',
                  description:
                      'Publica recursos, anuncios y mensajes para mantener informada a tu comunidad educativa.',
                ),
                // Diapositiva 3
                _buildPage(
                  title: 'Colabora en grupos',
                  description:
                      'Crea grupos de estudio, comparte ideas y colabora con otros maestros y estudiantes en proyectos educativos.',
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildPageIndicator(),
          ),
          SizedBox(height: 20),
          _currentPage != 2
              ? ElevatedButton(
                  onPressed: () {
                    _pageController.nextPage(
                        duration: Duration(milliseconds: 500),
                        curve: Curves.ease);
                  },
                  child: Text('Siguiente'),
                )
              : ElevatedButton(
                  onPressed: _finishOnboarding,
                  child: Text('Empezar'),
                ),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPage({required String title, required String description}) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            description,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageIndicator() {
    List<Widget> indicators = [];
    for (int i = 0; i < 3; i++) {
      indicators.add(i == _currentPage ? _indicator(true) : _indicator(false));
    }
    return indicators;
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 150),
      margin: EdgeInsets.symmetric(horizontal: 8),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
}
