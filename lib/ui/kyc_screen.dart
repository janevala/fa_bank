import 'dart:ui';

import 'package:community_material_icon/community_material_icon.dart';
import 'package:fa_bank/bloc/kyc_bloc.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/ui/fa_color.dart';
import 'package:fa_bank/ui/login_screen.dart';
import 'package:fa_bank/utils/list_utils.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';
import 'package:fa_bank/widget/spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:lipsum/lipsum.dart' as lipsum;

class KycScreen extends StatefulWidget {
  static const String route = '/kyc_screen';

  @override
  _KycScreenState createState() => _KycScreenState();
}

final SharedPreferencesManager _sharedPreferencesManager =
    locator<SharedPreferencesManager>();

class _KycScreenState extends State<KycScreen> {
  final KycBloc _kycBloc = KycBloc(KycInitial());
  bool _spin = true;
  PageController _pageController = PageController();
  var _currentPageValue = 0.0;
  List<Widget> _pageList = [];
  List<String> _countryList = [];
  String _countryOfBirth, _countryOfRecidency;
  final TextEditingController _controllerDate = TextEditingController();
  VideoPlayerController _videoController;
  Future<void> _initializeVideoPlayerFuture;
  bool _videoFadeIn = false;
  int _incomeGroup = -1;
  double _screenWidth,  _screenHeight;
  bool _giveConsent = false;
  bool _readConsent = false;

  @override
  void initState() {
    super.initState();

    var asset = 'assets/demo.mp4';
    _videoController = VideoPlayerController.asset(asset);
    _initializeVideoPlayerFuture = _videoController.initialize();
    _videoController.setLooping(false);

    _countryList = ListUtils.getCountries();
    _countryOfBirth = _countryList.first;
    _countryOfRecidency = _countryList.first;

    _doRefreshToken();
  }

  @override
  void dispose() {
    _videoController.dispose();

    super.dispose();
  }

  _showToast(BuildContext context, var text) {
    Scaffold.of(context).showSnackBar(SnackBar(duration: Duration(milliseconds: 500), content: Text(text)));
  }

  _doOnExpiry() async {
    if (_sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyAuthMSecs))
      await _sharedPreferencesManager.clearKey(SharedPreferencesManager.keyAuthMSecs);
  }

  _doRefreshToken() async {
    _kycBloc.add(KycEvent());
  }

  _logout(BuildContext context) {
    locator<SharedPreferencesManager>().clearSessionRelated();
    Navigator.pushNamedAndRemoveUntil(context, LoginScreen.route, (r) => false);
  }

  _buildPageList() {
    _pageList.add(_welcomeWidget());
    _pageList.add(_identifyVerificationGeneral());
    _pageList.add(_identifyVerificationRegisteredAddress());
    _pageList.add(_identifyVerificationSourceOfFunds());
//    _pageList.add(_identifyVerificationSustainabilityTest());
    _pageList.add(_askConsent());
//    _pageList.add(_submitDocuments());
    _pageList.add(_videoWidget());
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;

    _buildPageList();

    _pageController.addListener(() {
      setState(() {
        _currentPageValue = _pageController.page;
      });
    });

    return Scaffold(
      body: BlocProvider<KycBloc>(
        create: (context) => _kycBloc,
        child: BlocBuilder<KycBloc, KycState>(
          builder: (context, state) {
            if (state is KycLoading) {
              _spin = true;
            } else if (state is KycSuccess) {
              _spin = false;
              return Center(
                child: _widgetMainView(context),
              );
            } else if (state is KycCache) {
              _spin = false;
              return Center(
                child: Text('KycCache', style: Theme.of(context).textTheme.subtitle2),
              );
            } else if (state is KycFailure) {
              _spin = false;
              return Center(
                child: Text('KycFailure', style: Theme.of(context).textTheme.subtitle2),
              );
            }

            return Spinner();
          },
        ),
      ),
    );
  }

  Widget _widgetMainView(BuildContext context) {
    return PageView.builder(
      physics: NeverScrollableScrollPhysics(),
      controller: _pageController,
      itemBuilder: (context, position) {
        return Transform(
          transform: Matrix4.identity()..rotateY(_currentPageValue - position)..rotateZ(_currentPageValue - position),
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      FaColor.red[900],
                      FaColor.red[900],
                      FaColor.red[50]
                    ])),
            child: Stack(
              children: [
                _pageList[position],
                _widgetOneButton('ASDF')
              ],
            ),
          ),
        );

        /*if (position == _currentPageValue.floor()) {
          return Transform(
            transform: Matrix4.identity()..rotateY(_currentPageValue - position)..rotateZ(_currentPageValue - position),
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                    FaColor.red[900],
                    FaColor.red[900],
                    FaColor.red[50]
                  ])),
              child: Stack(
                children: [
                  _pageList[position],
                  _widgetOneButton('ASDF')
                ],
              ),
            ),
          );
        } else if (position == _currentPageValue.floor() + 1) {
          return Transform(
            transform: Matrix4.identity()..rotateY(_currentPageValue - position)..rotateZ(_currentPageValue - position),
            child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                      FaColor.red[900],
                      FaColor.red[900],
                      FaColor.red[50]
                    ])),
                child: Container(
                  color: Colors.transparent,
                )),
          );
        } else {
          return Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                  FaColor.red[900],
                  FaColor.red[900],
                  FaColor.red[50]
                ])),
            child: Center(
              child: Text("Page else", style: TextStyle(color: Colors.white, fontSize: 22.0)),
            ),
          );
        }*/
      },
      itemCount: _pageList.length,
    );
  }

  Widget _welcomeWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: Colors.white,
                ),
                borderRadius: BorderRadius.all(Radius.circular(5))),
            child: Icon(CommunityMaterialIcons.airplane_takeoff, size: 120, color: Colors.white),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text("Welcome to your online bank. Please take few minutes to fill your personal information and watch introduction video. Lets get started!",
              style: TextStyle(color: Colors.white, fontSize: 20)),
          )
        ],
      ),
    );
  }

  Widget _identifyVerificationGeneral() {
    return Center(
      child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: Colors.white,
              ),
              borderRadius: BorderRadius.all(Radius.circular(5))),
          child: Icon(CommunityMaterialIcons.account_question, size: 120, color: Colors.white),
        ),
        Text("Identity verification: General (1/7)", style: TextStyle(color: Colors.white, fontSize: 20)),
        _widgetGenFirstLine(),
        _widgetGenSecondLine(),
        _widgetGenThirdLine()
      ],
    ),
    );
  }

  Widget _identifyVerificationRegisteredAddress() {
    return Center(
      child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: Colors.white,
              ),
              borderRadius: BorderRadius.all(Radius.circular(5))),
          child: Icon(CommunityMaterialIcons.map_marker, size: 120, color: Colors.white),
        ),
        Text("Identity verification: Registered address", style: TextStyle(color: Colors.white, fontSize: 20)),
        _widgetAddrFirstLine(),
        _widgetAddrSecondLine(),
        _widgetAddrThirdLine()
      ],
    ),
    );
  }

  Widget _radioFundSource({String title, int value, Function onChanged}) {
    return Theme(
      data: Theme.of(context).copyWith(
          unselectedWidgetColor: Colors.white,
      ),
      child: RadioListTile(
        activeColor: Colors.white,
        value: value,
        groupValue: _incomeGroup,
        onChanged: onChanged,
        title: Text(title, style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _identifyVerificationSourceOfFunds() {
    return Center(
      child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: Colors.white,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  child: Icon(CommunityMaterialIcons.map_marker, size: 120, color: Colors.white),
                ),
                Text("Identity verification: Source of funds", style: TextStyle(color: Colors.white, fontSize: 20)),
                _radioFundSource(
                  title: "Employee",
                  value: 0,
                  onChanged: (newValue) => setState(() => _incomeGroup = newValue),
                ),
                _radioFundSource(
                  title: "Trader / Investor",
                  value: 1,
                  onChanged: (newValue) => setState(() => _incomeGroup = newValue),
                ),
                _radioFundSource(
                  title: "Freelance",
                  value: 2,
                  onChanged: (newValue) => setState(() => _incomeGroup = newValue),
                ),
                _radioFundSource(
                  title: "Student",
                  value: 3,
                  onChanged: (newValue) => setState(() => _incomeGroup = newValue),
                ),
                _radioFundSource(
                  title: "Business Owner",
                  value: 4,
                  onChanged: (newValue) => setState(() => _incomeGroup = newValue),
                ),
                _radioFundSource(
                  title: "Unemployed / Retired",
                  value: 5,
                  onChanged: (newValue) => setState(() => _incomeGroup = newValue),
                ),
              ],
            );
          }
      ),
    );
  }

  Widget _identifyVerificationSustainabilityTest() {
    return Center(child: Text("Identity verification: Sustainability test", style: TextStyle(color: Colors.white, fontSize: 20)));
  }

  Widget _askConsent() {
    var lipsumText = lipsum.createText(numParagraphs: 3, numSentences: 6);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: Colors.white,
                ),
                borderRadius: BorderRadius.all(Radius.circular(5))),
            child: Icon(CommunityMaterialIcons.check, size: 120, color: Colors.white),
          ),
          Text("Consent and acceptance of risk in digital assets investment", style: TextStyle(color: Colors.white, fontSize: 20)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Container(
                  height: _screenHeight * 0.4,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                        setState(() {
                          _readConsent = true;
                        });
                        return true;
                      }

                      return false;
                    },
                    child: SingleChildScrollView(
                      child: (Text(lipsumText, style: TextStyle(color: Colors.white, fontSize: 18))),
                    ),
                  ),
                );
              }),
          ),
          StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: Theme.of(context).accentColor,
                    unselectedWidgetColor: Colors.white,
                  ),
                  child: CheckboxListTile(
                    title: Text("The customer has read and understood the risks of trading the Digital Assets as explained under this document for acknowledgment", style: TextStyle(color: Colors.white, fontSize: 18)),
                    value: _giveConsent,
                    onChanged: (newValue) {
                      _readConsent ? setState(() => _giveConsent = newValue) : false;
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              })
        ],
      ),
    );
  }

  Widget _submitDocuments() {
    return Center(child: Text("Document verification: Take your selfie photo, with the first page of your passport. When the process is completed, you will see the message: Verification is in progress. Due to the high traffic on our platform, the account verification process may take 3 - 7 days. We are doing our best to proceed with your submission as soon as possible.",
          style: TextStyle(color: Colors.white, fontSize: 20)),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('d MMM yyyy').format(dateTime);
  }

  Widget _widgetGenFirstLine() {
    return Padding(
        padding: EdgeInsets.only(left: 12, right: 12, top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextField(
                    style: Theme.of(context).textTheme.subtitle2.merge(TextStyle(color: Colors.white)),
                    controller: null,
                    keyboardType: TextInputType.text,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'First name',
                      hintStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    )),
              ),
            ),
            Container(width: 12),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextField(
                    style: Theme.of(context).textTheme.subtitle2.merge(TextStyle(color: Colors.white)),
                    controller: null,
                    keyboardType: TextInputType.text,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Last name',
                      hintStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    )),
              ),
            )
          ],
        ));
  }

  Widget _widgetGenSecondLine() {
    return Padding(
        padding: EdgeInsets.only(left: 12, right: 12, top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextField(
                    style: Theme.of(context).textTheme.subtitle2.merge(TextStyle(color: Colors.white)),
                    controller: null,
                    keyboardType: TextInputType.text,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'National ID card',
                      hintStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    )),
              ),
            ),
            Container(width: 12),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () async {
                    DateTime now = DateTime.now();
                    DateTime picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(now.year - 30, now.month, now.day),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(now.year, now.month, now.day)
                    );
                    if (picked != null) {
                      setState(() {
                        _controllerDate.text = _formatDateTime(picked);
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                        style: Theme.of(context).textTheme.subtitle2.merge(TextStyle(color: Colors.white)),
                        controller: _controllerDate,
                        keyboardType: TextInputType.text,
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: 'Date of birth',
                          hintStyle: TextStyle(color: Colors.white),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                          border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        )),
                  ),
                ),
              ),
            )
          ],
        ));
  }

  Widget _widgetGenThirdLine() {
    return Padding(
        padding: EdgeInsets.only(left: 12, right: 12, top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Theme.of(context).accentColor,
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                          value: _countryOfBirth,
                          onChanged: (String newValue) {
                            setState(() {
                              _countryOfBirth = newValue;
                            });
                          },
                          items: _countryList.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                        ),
                      );
                    }
                ),
              ),
            ),
            Container(width: 12),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextField(
                    style: Theme.of(context).textTheme.subtitle2.merge(TextStyle(color: Colors.white)),
                    controller: null,
                    keyboardType: TextInputType.text,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Phone number',
                      hintStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    )),
              ),
            )
          ],
        ));
  }

  Widget _widgetAddrFirstLine() {
    return Padding(
        padding: EdgeInsets.only(left: 12, right: 12, top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Theme.of(context).accentColor,
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                          value: _countryOfBirth,
                          onChanged: (String newValue) {
                            setState(() {
                              _countryOfBirth = newValue;
                            });
                          },
                          items: _countryList.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                        ),
                      );
                    }
                ),
              ),
            ),
            Container(width: 12),
            Flexible(
              child: Container(),
            )
          ],
        ));
  }

  Widget _widgetAddrSecondLine() {
    return Padding(
        padding: EdgeInsets.only(left: 12, right: 12, top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextField(
                    style: Theme.of(context).textTheme.subtitle2.merge(TextStyle(color: Colors.white)),
                    controller: null,
                    keyboardType: TextInputType.text,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Address line 1',
                      hintStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    )),
              ),
            ),
            Container(width: 12),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextField(
                    style: Theme.of(context).textTheme.subtitle2.merge(TextStyle(color: Colors.white)),
                    controller: null,
                    keyboardType: TextInputType.text,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Address line 2',
                      hintStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    )),
              ),
            )
          ],
        ));
  }

  Widget _widgetAddrThirdLine() {
    return Padding(
        padding: EdgeInsets.only(left: 12, right: 12, top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextField(
                    style: Theme.of(context).textTheme.subtitle2.merge(TextStyle(color: Colors.white)),
                    controller: null,
                    keyboardType: TextInputType.text,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Building (if applicable)',
                      hintStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    )),
              ),
            ),
            Container(width: 12),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextField(
                    style: Theme.of(context).textTheme.subtitle2.merge(TextStyle(color: Colors.white)),
                    controller: null,
                    keyboardType: TextInputType.text,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Post code',
                      hintStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    )),
              ),
            )
          ],
        ));
  }

  Widget _videoWidget() {
    return VisibilityDetector(
      key: UniqueKey(),
      onVisibilityChanged: (VisibilityInfo info) {
        var visiblePercentage = info.visibleFraction * 100;
        if (visiblePercentage < 1) {
          _videoController.pause();
          setState(() {
            _videoFadeIn = false;
          });
        } else {
          _videoController.play();
          setState(() {
            _videoFadeIn = true;
          });
        }
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 150),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5.0),
            child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: FutureBuilder(
                      future: _initializeVideoPlayerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return AnimatedOpacity(
                              opacity: _videoFadeIn ? 0 : 1,
                              duration: Duration(milliseconds: 5000),
                              child: VideoPlayer(_videoController));
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      },
                    ))),
          ),
        ),
      ),
    );
  }

  Widget _widgetOneButton(String text) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 80,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: SizedBox.expand(
              child: FlatButton(
                  child: PlatformText(text, style: Theme.of(context).textTheme.headline6.merge(TextStyle(color: Colors.white))),
                  color: FaColor.red[900],
                  onPressed: () {
                    _pageController.nextPage(duration: Duration(milliseconds: 500), curve: ListUtils.getCurve(0));
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0))),
            ),
          ),
        ));
  }

  Widget _widgetTwoButton() {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 80,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: SizedBox.expand(
                      child: FlatButton(
                          child: PlatformText('Back', style: Theme.of(context).textTheme.headline6.merge(TextStyle(color: Colors.white))),
                          color: FaColor.red[900],
                          onPressed: () {
                            _pageController.previousPage(duration: Duration(milliseconds: 500), curve: ListUtils.getCurve(0));
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0))),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: SizedBox.expand(
                      child: FlatButton(
                          child: PlatformText('Next', style: Theme.of(context).textTheme.headline6.merge(TextStyle(color: Colors.white))),
                          color: FaColor.red[900],
                          onPressed: () {
                            _pageController.nextPage(duration: Duration(milliseconds: 500), curve: ListUtils.getCurve(0));
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0))),
                    ),
                  ),
                ),
              ]),
        ));
  }
}
