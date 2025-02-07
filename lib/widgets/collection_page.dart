// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:infusion_timer/tea.dart';
import 'package:infusion_timer/widgets/preferences_page.dart';
import 'package:infusion_timer/widgets/tea_actions_bottom_sheet.dart';
import 'package:infusion_timer/widgets/tea_card.dart';
import 'package:infusion_timer/widgets/tea_input_dialog.dart';
import 'package:infusion_timer/widgets/timer_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart' show rootBundle;

const String TEAS_SAVE_KEY = "teas";

class CollectionPage extends StatefulWidget {
  CollectionPage({Key key}) : super(key: key);

  @override
  _CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  List<Tea> _teas = [];
  Map<double, int> _savedSessions = {};
  String _versionName = "";

  void _deleteTea(Tea tea) async {
    var prefs = await SharedPreferences.getInstance();
    // delete active session if any
    setState(() {
      _teas.remove(tea);
    });
    await prefs.remove(SESSION_SAVE_PREFIX + tea.id.toString());
    await _saveTeas();
  }

  void _updateTea(Tea tea) async {
    // tea was changed already and the change needs to be handled
    var prefs = await SharedPreferences.getInstance();
    var savedInfusion = prefs.getInt(SESSION_SAVE_PREFIX + tea.id.toString());
    if (savedInfusion != null && savedInfusion >= tea.infusions.length) {
      await prefs.remove(SESSION_SAVE_PREFIX + tea.id.toString());
    }
    _loadSessions();
    _saveTeas();
  }

  void _saveTeas() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        TEAS_SAVE_KEY, _teas.map((tea) => jsonEncode(tea)).toList());
  }

  void _loadSessions() async {
    var prefs = await SharedPreferences.getInstance();
    setState(() {
      _teas.forEach((tea) {
        var teaSession = prefs.getInt(SESSION_SAVE_PREFIX + tea.id.toString());
        if (teaSession != null) {
          _savedSessions[tea.id] = teaSession;
        } else {
          _savedSessions.remove(tea.id);
        }
      });
    });
  }

  void _loadTeas() async {
    var prefs = await SharedPreferences.getInstance();
    var savedTeaStrings = prefs.getStringList(TEAS_SAVE_KEY);
    if (savedTeaStrings == null) {
      var teasJsonString =
          (await rootBundle.loadString('assets/default_data.json'));
      var teasJson = json.decode(teasJsonString) as List;
      setState(() {
        _teas = teasJson.map((jsonTea) => Tea.fromJson(jsonTea)).toList();
      });
    } else {
      setState(() {
        _teas = savedTeaStrings
            .map((teaJson) => Tea.fromJson(jsonDecode(teaJson)))
            .toList();
      });
    }
    // save to persist generated ids
    _saveTeas();
  }

  @override
  void initState() {
    super.initState();
    PreferencesPage.loadSettings();
    _loadTeas();
    _loadSessions();
    PackageInfo.fromPlatform().then((value) => _versionName = value.version);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tea Collection")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration:
                  BoxDecoration(color: Theme.of(context).colorScheme.secondary),
              child: Text(
                "Infusion Tea Timer",
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Preferences"),
              onTap: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PreferencesPage(key: null)));
                // when returning from preferences, update vessel size
                setState(() {});
              },
            ),
            AboutListTile(
              icon: Icon(Icons.favorite),
              applicationIcon: Container(
                height: IconTheme.of(context).resolve(context).size,
                width: IconTheme.of(context).resolve(context).size,
                child: Image.asset(
                  "assets/icon_simple.png",
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
              applicationVersion: _versionName,
              applicationLegalese:
                  "Copyright (c) 2021 Sesu8642\n\nhttps://github.com/Sesu8642/InfusionTimer",
              aboutBoxChildren: [
                Text(
                  "\nMany thanks to Mei Leaf (meileaf.com) for their permission to include data from their brewing guide!",
                  style: TextStyle(fontSize: 14),
                )
              ],
            )
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: _teas.length,
        itemBuilder: (context, i) {
          return TeaCard(_teas[i], (tea) async {
            var future = Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TimerPage(tea: tea)),
            );
            setState(
              () {
                // bring tea to the first position
                _teas.remove(tea);
                _teas.insert(0, tea);
                _saveTeas();
              },
            );
            await future;
            // load sessions again because there might be a change
            await _loadSessions();
          },
              (tea) => {
                    showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) =>
                            new TeaActionsBottomSheet(
                                tea,
                                (tea) => {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            new TeaInputDialog(
                                          tea,
                                          (tea) {
                                            _updateTea(tea);
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pop();
                                          },
                                          (tea) {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      )
                                    }, (tea) {
                              _deleteTea(tea);
                            }))
                  },
              PreferencesPage.teaVesselSizeMlPref,
              _savedSessions[_teas[i].id]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) => new TeaInputDialog(
              new Tea.withGeneratedId(null, null, null, [], null),
              (tea) {
                setState(
                  () {
                    _teas.insert(0, tea);
                    _saveTeas();
                  },
                );
                Navigator.of(context).pop();
              },
              (tea) {
                Navigator.of(context).pop();
              },
            ),
          );
        },
        tooltip: 'Add Tea',
        child: Icon(Icons.add),
      ),
    );
  }
}
