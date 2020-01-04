import 'package:flutter/material.dart';
import 'package:price_alarm/originro/originro.dart';
import 'package:price_alarm/pricealarm/price_alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsForm extends StatefulWidget {
  SettingsForm();

  @override
  SettingsFormState createState() {
    return SettingsFormState();
  }
}

// Define a corresponding State class.
// This class holds data related to the form.
class SettingsFormState extends State<SettingsForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final _settings = new Settings();
    // Build a Form widget using the _formKey created above.
    return FutureBuilder<Settings>(
      future: new SettingsService().getSettings(),
      builder: (BuildContext context, AsyncSnapshot<Settings> snapshot) {
        if (snapshot.hasData) {
          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Enter the API Key',
                              labelText: 'API Key',
                            ),
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                            onSaved: (val) => _settings.apiKey = val,
                            initialValue: snapshot.data.apiKey,
                          )),
                      IconButton(
                          icon: Icon(
                            Icons.help, color: Colors.blueAccent, size: 30.0,),
                          onPressed: () {
                            showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(5.0)),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Padding(padding: EdgeInsets.all(10.0),
                                            child: Text(
                                              "The API Key is needed to load information via the OriginsRO API. It will be stored locally on your device and is NOT shared to any other person. \n \n"
                                                  "How to generate an API Key:\n"
                                                  "1. Log in to your OriginsRO Control Panel (https://cp.originsro.org/masteraccount/view/).\n"
                                                  "2. Follow the menu to Master Account -> My Account.\n"
                                                  "3. Press the settings button on the row with API Key.\n"
                                                  "4. Generate the API Key.\n",
                                              style: TextStyle(fontSize: 16.0),
                                            ),
                                          ),
                                          RaisedButton(
                                            child: Text('Close'),
                                            onPressed: () async {
                                              Navigator.pop(context);
                                            },
                                          ),
                                          SizedBox(height: 10.0,)
                                        ]),
                                  );
                                });
                          }),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: RaisedButton(
                      onPressed: () async {
                        // Validate returns true if the form is valid, or false
                        // otherwise.
                        final FormState form = _formKey.currentState;
                        if (form.validate()) {
                          // If the form is valid, display a Snackbar.
                          form.save();
                          await new SettingsService().saveSettings(_settings);
                          Scaffold.of(context).showSnackBar(
                              SnackBar(content: Text('Processing Data')));
                          if ((await new ItemRepository().items("guard"))
                              .length ==
                              0) {
                            syncItemsWithDialog(context, exitScreen);
                          } else {
                            exitScreen(context);
                          }
                        }
                      },
                      child: Text('Submit'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: RaisedButton(
                      onPressed: () async {
                        final FormState form = _formKey.currentState;
                        if (form.validate()) {
                          form.save();
                          await new SettingsService().saveSettings(_settings);
                          syncItemsWithDialog(context, null);
                        }
                      },
                      child: Text('Sync item database'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              child: CircularProgressIndicator(),
              width: 60,
              height: 60,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Awaiting result...'),
            )
          ],
        );
      },
    );
  }

  void exitScreen(BuildContext context) {
    if (!Navigator.pop(context)) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (BuildContext context) {
            return PriceAlarmWidget();
          }));
    }
  }

  void syncItemsWithDialog(BuildContext context, Function action) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
          child: SizedBox(
            height: 100.0,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: CircularProgressIndicator()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text("Importing items"),
                )
              ],
            ),
          ),
        );
      },
    );

      new OriginRoService().syncItems().whenComplete(() {
        Navigator.pop(context);
        if (action != null) {
          action(context);
        }
      }).catchError((Exception e) => Scaffold.of(context).showSnackBar(
          SnackBar( duration: Duration(seconds: 10),content: Text(e.toString(),style:TextStyle(color: Colors.redAccent),)))
    );
  }
}

class SettingsService {
  saveSettings(Settings settings) async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString('apiKey', settings.apiKey);
  }

  Future<Settings> getSettings() async {
    var prefs = await SharedPreferences.getInstance();
    var settings = new Settings();
    settings.apiKey = prefs.getString('apiKey');

    return settings;
  }
}

class Settings {
  String apiKey;
}
