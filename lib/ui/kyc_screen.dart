import 'dart:io';
import 'dart:ui';

import 'package:community_material_icon/community_material_icon.dart';
import 'package:fa_bank/bloc/kyc_bloc.dart';
import 'package:fa_bank/ui/camera_screen.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/ui/fa_color.dart';
import 'package:fa_bank/ui/landing_screen.dart';
import 'package:fa_bank/ui/login_screen.dart';
import 'package:fa_bank/utils/list_utils.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';
import 'package:fa_bank/utils/utils.dart';
import 'package:fa_bank/widget/spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
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
  TextEditingController _controllerDate = TextEditingController();
  VideoPlayerController _videoController;
  Future<void> _initializeVideoPlayerFuture;
  int _incomeGroup = -1;
  double _screenWidth,  _screenHeight;
  bool _giveConsent = false;
  bool _readConsent = false;

  Permission _cameraPermission = Permission.camera;
  PermissionStatus _cameraPermissionStatus = PermissionStatus.undetermined;
  bool _cameraPermissionsOk = false;
  bool _cameraPictureOk = false;

  bool _doMockWait = false;
  
  List<List<String>> _questionnaire = ListUtils.getSustainabilityTest();

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('d MMM yyyy').format(dateTime);
  }

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

  _checkCameraPermission(StateSetter setState) async {
    final _s = await _cameraPermission.status;

    setState(() {
      _cameraPermissionStatus = _s;
      if (_cameraPermissionStatus.isGranted) _cameraPermissionsOk = true;
    });
  }

  Future<void> _requestCameraPermission(StateSetter setState) async {
    final _s = await _cameraPermission.request();

    setState(() {
      _cameraPermissionStatus = _s;
      if (_cameraPermissionStatus.isGranted) _cameraPermissionsOk = true;
    });
  }

  Future<void> _handleCameraAndReturnValue(StateSetter setState) async {
    final _result = await Navigator.pushNamed(context, CameraScreen.route);//we assume dynamic return type is bool, it would be better to be explicit
    if (_result) {
      setState(() {
        _cameraPictureOk = true;
      });
    }
  }

  Future<void> _mockWait(StateSetter setState) async {
    setState(() {
      _doMockWait = true;
    });
    int rand = Utils.randomIntRange(1500, 2500);
    await Future.delayed(Duration(milliseconds: rand));
    setState(() {
      _doMockWait = false;
    });
  }

  _buildPageList() {
    _pageList.add(_welcomeWidget());
    _pageList.add(_identifySustainabilityTest());
    _pageList.add(_identifyGeneral());
    _pageList.add(_identifyRegisteredAddress());
    _pageList.add(_widgetSourceOfFunds());
    _pageList.add(_submitDocuments());
    _pageList.add(_widgetConsent());
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
      body: BlocProvider<KycBloc>(//currently not used use for anything, but keeping the wiring for now just in case
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
            child: _pageList[position],
          ),
        );
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
                    width: 3
                ),
                borderRadius: BorderRadius.all(Radius.circular(20))),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Icon(CommunityMaterialIcons.airplane_takeoff, size: 100, color: Colors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text("Welcome to your online bank. Please take few minutes to fill your personal information and watch introduction video.",
                style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          Container(height: 46),
          Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 80,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: SizedBox.expand(
                    child: FlatButton(
                        child: PlatformText("Lets Start!", style: Theme.of(context).textTheme.headline6.merge(TextStyle(color: Colors.white))),
                        color: FaColor.red[900],
                        onPressed: () async {
                          _pageController.nextPage(duration: Duration(milliseconds: 600), curve: ListUtils.getCurve(0));
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0))),
                  ),
                ),
              ))
        ],
      ),
    );
  }

  Widget _identifyGeneral() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                      color: Colors.white,
                      width: 3
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(CommunityMaterialIcons.account_question_outline, size: 100, color: Colors.white),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text("Identity: General", style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            _widgetGenFirstLine(),
            _widgetGenSecondLine(),
            _widgetGenThirdLine(),
            Container(height: 32),
            _widgetBackNext()
          ],
        ),
      ),
    );
  }

  Widget _identifyRegisteredAddress() {
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
                    width: 3
                ),
                borderRadius: BorderRadius.all(Radius.circular(20))),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Icon(CommunityMaterialIcons.map_marker, size: 100, color: Colors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text("Identity: Registered Address", style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          _widgetAddrFirstLine(),
          _widgetAddrSecondLine(),
          _widgetAddrThirdLine(),
          Container(height: 32),
          _widgetBackNext()
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
        dense: true,
        activeColor: Colors.white,
        value: value,
        groupValue: _incomeGroup,
        onChanged: onChanged,
        title: Text(title, style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _widgetSourceOfFunds() {
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
                          width: 3
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(CommunityMaterialIcons.account_cash_outline, size: 100, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Identity: Source of Funds", style: TextStyle(color: Colors.white, fontSize: 20)),
                ),
                _radioFundSource(
                  title: "Inheritance",
                  value: 0,
                  onChanged: (newValue) => setState(() => _incomeGroup = newValue),
                ),
                _radioFundSource(
                  title: "Salary",
                  value: 1,
                  onChanged: (newValue) => setState(() => _incomeGroup = newValue),
                ),
                _radioFundSource(
                  title: "Ownership of a Business",
                  value: 2,
                  onChanged: (newValue) => setState(() => _incomeGroup = newValue),
                ),
                _radioFundSource(
                  title: "Investments",
                  value: 3,
                  onChanged: (newValue) => setState(() => _incomeGroup = newValue),
                ),
                Container(height: 32),
                _widgetBackNext()

              ],
            );
          }
      ),
    );
  }


  String _selection = '';

  Widget _identifySustainabilityTest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 64, left: 16, right: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                        color: Colors.white,
                        width: 3
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(CommunityMaterialIcons.format_list_bulleted_type, size: 100, color: Colors.white),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text("Financial Sustainability Questionnaire", style: TextStyle(color: Colors.white, fontSize: 20)),
              ),
              Container(height: 16),
              Column(
                children: <Widget>[
                  for (var i = 0; i < _questionnaire.length; i++)
                    for (var j = 0; j < _questionnaire[i].length; j++)
                      _widgetColumnElement(i, j)
                ]
              ),
              Container(height: 16),
              _widgetBackNext()
            ],
          ),
        ),
      ),
    );
  }

  Widget _widgetColumnElement(int group, int question) {
    if (question == 0) {
      return Padding(
        padding: EdgeInsets.only(top: 16),
        child: Align(
          alignment: Alignment.centerLeft,
            child: Text(_questionnaire[group][0], style: TextStyle(color: Colors.white, fontSize: 16))),
      );
    } else {
      return Theme(
        data: Theme.of(context).copyWith(
          unselectedWidgetColor: Colors.white,
        ),
        child: RadioListTile(
          dense: true,
          activeColor: Colors.white,
          value: _questionnaire[group][question],
          groupValue: _questionnaire[group],
          onChanged: (val) {
            setState(() {
              _selection = val;
            });
          },
          title: Text(_questionnaire[group][question], style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  Widget _widgetConsent() {
    var lipsumText = lipsum.createText(numParagraphs: 4, numSentences: 6);

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
                    width: 3
                ),
                borderRadius: BorderRadius.all(Radius.circular(20))),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Icon(CommunityMaterialIcons.check, size: 100, color: Colors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text("Consent and acceptance of risk in investments (please scroll to the end)", style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Container(
                    height: _screenHeight * 0.35,
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
                        child: (Text(lipsumText, style: TextStyle(color: Colors.white, fontSize: 16))),
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
                    dense: true,
                    title: Text("I have read and understood the risks of trading, as explained in the document above", style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: _giveConsent,
                    onChanged: (newValue) {
                      _readConsent ? setState(() => _giveConsent = newValue) : false;
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              }),
          Container(height: 16),
          _widgetBackNext()
        ],
      ),
    );
  }

  Widget _submitDocuments() {
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
                          width: 3
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(CommunityMaterialIcons.camera, size: 100, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Identity: Documents", style: TextStyle(color: Colors.white, fontSize: 20)),
                ),
                _widgetTogglePermissionCamera(setState),
                Container(height: 16),
                Visibility(
                    visible: _cameraPictureOk,
                    child: _widgetBackNext())
              ],
            );
          }),
    );
  }

  Widget _widgetTogglePermissionCamera(StateSetter setState) {
    _checkCameraPermission(setState);

    return Center(
      child: Column(
        children: [
          Visibility(
            visible: !_cameraPermissionsOk,
            child: FlatButton(
              onPressed: () {
                _requestCameraPermission(setState);
              },
              child: Text("Click to check the camera permission", style: TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.underline)),
            ),
          ),
          Visibility(
            visible: _cameraPermissionsOk,
            child: FlatButton(
              onPressed: () => _handleCameraAndReturnValue(setState),
              child:  Text("Open camera and take selfie along with the first page of your passport", style: TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.underline)),
            ),
          ),
        ],
      )
    );

  }

  Widget _videoWidget() {
    return VisibilityDetector(
      key: UniqueKey(),
      onVisibilityChanged: (VisibilityInfo info) {
        var visiblePercentage = info.visibleFraction * 100;
        if (visiblePercentage < 1) {
          _videoController.pause();
        } else {
          _videoController.play();
        }
      },
      child: Center(
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                            width: MediaQuery.of(context).size.width * 0.95,
                            child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: FutureBuilder(
                                  future: _initializeVideoPlayerFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.done) {
                                      return VideoPlayer(_videoController);
                                    } else {
                                      return Center(child: CircularProgressIndicator());
                                    }
                                  },
                                ))),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("Account verification process normally takes 1 - 2 business days. When the verification process is completed, you will get full access to all features in the app. Please watch the introduction video and then start exploring the app!",
                            style: TextStyle(color: Colors.white, fontSize: 20)),
                      ),
                      Container(height: 32),
                      Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 80,
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: SizedBox.expand(
                                child: FlatButton(
                                    child: PlatformText("Ready!", style: Theme.of(context).textTheme.headline6.merge(TextStyle(color: Colors.white))),
                                    color: FaColor.red[900],
                                    onPressed: () async {
                                      _sharedPreferencesManager.putBool(SharedPreferencesManager.keyKycCompleted, true);

                                      _videoController.pause();

                                      await _mockWait(setState);

                                      Navigator.pushNamedAndRemoveUntil(context, LandingScreen.route, (r) => false);
                                    },
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0))),
                              ),
                            ),
                          ))
                    ],
                  ),
                  Visibility(
                    visible: _doMockWait,
                    child: Spinner(),
                  )
                ],
              );
            }),
      ),
    );
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
                          value: _countryOfRecidency,
                          onChanged: (String newValue) {
                            setState(() {
                              _countryOfRecidency = newValue;
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
                      hintText: 'Building',
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

  Widget _widgetBackNext() {
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0))),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0))),
                    ),
                  ),
                ),
              ]),
        ));
  }
}
