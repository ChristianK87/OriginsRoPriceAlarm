
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
      builder: (BuildContext context, AsyncSnapshot<Settings> snapshot){
        if(snapshot.hasData){
          return Form(
            key: _formKey,
            child:  Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
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
                          Scaffold.of(context)
                              .showSnackBar(SnackBar(content: Text('Processing Data')));
                          if(!Navigator.pop(context)){
                            Navigator.of(context).pushReplacement( MaterialPageRoute<void>(
                              builder: (BuildContext context) {
                                return PriceAlarmWidget();
                              }
                              ));
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
                        form.save();
                        await new SettingsService().saveSettings(_settings);
                        await new OriginRoService().syncItems();
                        Scaffold.of(context)
                            .showSnackBar(SnackBar(content: Text('Importing items')));
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

class Settings{
  String apiKey;
}