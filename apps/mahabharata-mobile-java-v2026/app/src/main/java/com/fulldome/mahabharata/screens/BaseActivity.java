package com.fulldome.mahabharata.screens;

import android.content.Intent;
import android.os.Bundle;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.facebook.CallbackManager;

public abstract class BaseActivity extends AppCompatActivity {
	private CallbackManager manager;

	@Override
	protected void onCreate(@Nullable Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		manager = CallbackManager.Factory.create();
	}

	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);
		manager.onActivityResult(requestCode, resultCode, data);
	}
}
