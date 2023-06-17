import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:weather_app/Model/CurrentCityDataModel.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/Model/ForecastDaysModel.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<CurrentCityDataModel> currentWeatherFuture;
  late StreamController<List<ForecastDaysModel>> streamForcastDays;

  var cityName = 'london';
  var lon;
  var lat;

  TextEditingController textEditingController = new TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    currentWeatherFuture = SendRequestCurrentWeather(cityName);
    streamForcastDays = StreamController<List<ForecastDaysModel>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Weather App"),
        elevation: 15,
        actions: <Widget>[
          PopupMenuButton<String>(itemBuilder: (BuildContext context) {
            return {'Setting', 'Log out'}.map((String Choice) {
              return PopupMenuItem(
                value: Choice,
                child: Text(Choice),
              );
            }).toList();
          }),
        ],
      ),
      body: FutureBuilder<CurrentCityDataModel>(
        future: currentWeatherFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            CurrentCityDataModel? cityDataModel = snapshot.data;
            SendRequest7DaysForecast(lat, lon);

            final formatter = DateFormat.jm();
            var sunrise = formatter.format(
                new DateTime.fromMillisecondsSinceEpoch(
                    cityDataModel!.sunrise * 1000,
                    isUtc: true));
            var sunset = formatter.format(
                new DateTime.fromMillisecondsSinceEpoch(
                    cityDataModel.sunset * 1000,
                    isUtc: true));

            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage('images/bg.jpg'),
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 10,
                  sigmaY: 10,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      SendRequestCurrentWeather(textEditingController.text);
                                    });
                                  },
                                  child: Text('Find')),
                            ),
                            Expanded(
                              child: TextField(
                                controller: textEditingController,
                                decoration: InputDecoration(
                                  hintStyle: TextStyle(color: Colors.white),
                                  hintText: "Enter City Name",
                                  border: UnderlineInputBorder(),
                                ),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Text(cityDataModel.cityName,
                            style:
                                TextStyle(color: Colors.white, fontSize: 35)),
                      ),
                      Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            cityDataModel.description,
                            style: TextStyle(color: Colors.grey, fontSize: 20),
                          )),
                      Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: Icon(Icons.wb_sunny_outlined,
                              color: Colors.white, size: 80)),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          cityDataModel.temp.toString() + "\u00B0",
                          style: TextStyle(color: Colors.white, fontSize: 70),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                "Max",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 20),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  cityDataModel.tempMax.toString() + "\u00B0",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Container(
                              width: 1,
                              height: 40,
                              color: Colors.white,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Column(
                              children: [
                                Text(
                                  "Min",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 20),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    cityDataModel.tempMin.toString() + "\u00B0",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Container(
                          color: Colors.grey[600],
                          height: 1,
                          width: double.infinity,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 100,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Center(
                            child: StreamBuilder<List<ForecastDaysModel>>(
                              stream: streamForcastDays.stream,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  List<ForecastDaysModel>? daysData =
                                      snapshot.data;

                                  return ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: 6,
                                      itemBuilder:
                                          (BuildContext contxt, int pos) {
                                        return listViewItems(daysData![pos + 1]);
                                      });
                                } else {
                                  return Center(
                                    child: JumpingDotsProgressIndicator(
                                      color: Colors.black,
                                      fontSize: 60,
                                      dotSpacing: 2,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Container(
                          color: Colors.grey[600],
                          height: 1,
                          width: double.infinity,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                Text(
                                  "Wind Speed",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    cityDataModel.windSpeed.toString() + " m/s",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Container(
                                width: 1,
                                height: 40,
                                color: Colors.white,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Column(
                                children: [
                                  Text(
                                    "Sunrise",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      sunrise,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Container(
                                width: 1,
                                height: 40,
                                color: Colors.white,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Column(
                                children: [
                                  Text(
                                    "Sunset",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      sunset,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Container(
                                width: 1,
                                height: 40,
                                color: Colors.white,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Column(
                                children: [
                                  Text(
                                    "Humidity",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      cityDataModel.humidity.toString() + "%",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Center(
              child: JumpingDotsProgressIndicator(
                color: Colors.black,
                fontSize: 60,
                dotSpacing: 2,
              ),
            );
          }
          //throw Future.error("sss");
        },
      ),
    );
  }

  Container listViewItems(ForecastDaysModel daysData) {
    return Container(
      height: 50,
      width: 70,
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Column(
          children: [
            Text(
              daysData.dateTime,
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            Icon(
              Icons.cloud,
              color: Colors.white,
            ),
            Text(
              daysData.temp.round().toString() + "\u00B0",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Future<CurrentCityDataModel> SendRequestCurrentWeather(
      String cityName) async {
    var apiKey = '12ce846fa9fb88deec949c001d8889fc';

    var response = await Dio().get(
      'https://api.openweathermap.org/data/2.5/weather',
      queryParameters: {'q': cityName, 'appid': apiKey, 'units': 'metric'},
    );

    lon = response.data["coord"]["lon"];
    lat = response.data["coord"]["lat"];

    var dataModel = CurrentCityDataModel(
        response.data["name"],
        response.data["coord"]["lon"],
        response.data["coord"]["lat"],
        response.data["weather"][0]["main"],
        response.data["weather"][0]["description"],
        response.data["main"]["temp"],
        response.data["main"]["temp_min"],
        response.data["main"]["temp_max"],
        response.data["main"]["pressure"],
        response.data["main"]["humidity"],
        response.data["wind"]["speed"],
        response.data["dt"],
        response.data["sys"]["country"],
        response.data["sys"]["sunrise"],
        response.data["sys"]["sunset"]);

    return dataModel;
  }

  void SendRequest7DaysForecast(lat, lon) async {
    List<ForecastDaysModel> list = [];

    var apiKey = '12ce846fa9fb88deec949c001d8889fc';

    try {
      var response = await Dio().get(
          "https://api.openweathermap.org/data/3.0/onecall",
          queryParameters: {
            'lat': lat,
            'lon': lon,
            'exclude': 'minutely,hourly',
            'appid': apiKey,
            'units': 'metric'
          });

      final formatter = DateFormat.MMMd();

      for (int i = 0; i < 8; i++) {
        var model = response.data['daily'][i];

        var dt = formatter.format(new DateTime.fromMillisecondsSinceEpoch(
            model['dt'] * 1000,
            isUtc: true));

        ForecastDaysModel forecastDaysModel = ForecastDaysModel(
            dt,
            model['temp']['day'],
            model['weather'][0]['main'],
            model['weather'][0]['description']);

        list.add(forecastDaysModel);
      }

      streamForcastDays.add(list);
    } on DioError catch (e) {
      print(e.response!.statusCode);
      print(e.message);
    }
  }
}
