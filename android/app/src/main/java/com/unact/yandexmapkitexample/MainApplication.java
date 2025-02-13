package com.unact.yandexmapkitexample;

import android.app.Application;

import com.yandex.mapkit.MapKitFactory;

public class MainApplication extends Application {
  @Override
  public void onCreate() {
    super.onCreate();
    MapKitFactory.setLocale("ru_RU");
    MapKitFactory.setApiKey("9d891a3e-91b4-49f2-8e6b-b42a8d7d8f13");
  }
}
