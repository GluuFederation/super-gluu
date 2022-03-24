package org.gluu.super_gluu.store.database;

import android.app.Application;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.AsyncTask;
import android.util.Log;

import androidx.room.Database;
import androidx.room.Room;
import androidx.room.RoomDatabase;
import androidx.room.TypeConverters;

import com.google.gson.Gson;

import org.apache.commons.codec.DecoderException;
import org.gluu.super_gluu.app.model.LogInfo;
import org.gluu.super_gluu.store.Converter.DateTimeConverter;
import org.gluu.super_gluu.store.Converter.LogStateConverter;
import org.gluu.super_gluu.store.dao.LogInfoEntryDAO;
import org.gluu.super_gluu.store.entity.LogInfoEntry;
import org.gluu.super_gluu.u2f.v2.store.AndroidKeyDataStore;
import org.gluu.super_gluu.store.dao.UserTokenEntryDAO;
import org.gluu.super_gluu.store.entity.UserTokenEntry;
import org.gluu.super_gluu.u2f.v2.model.TokenEntry;
import org.gluu.super_gluu.util.Utils;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Database(entities = {UserTokenEntry.class, LogInfoEntry.class}, exportSchema = false, version = 5)
@TypeConverters({LogStateConverter.class, DateTimeConverter.class})
public abstract class UserTokenEntryDatabase extends RoomDatabase {

    private static final String DB_NAME = "user_token_entry_db";
    private static UserTokenEntryDatabase instance;

    public static synchronized UserTokenEntryDatabase getInstance(Application application) {
        if (instance == null) {
            instance = Room.databaseBuilder(
                    application.getApplicationContext(),
                    UserTokenEntryDatabase.class,
                    DB_NAME
            ).fallbackToDestructiveMigration().build();
        }

        return instance;
    }

    public abstract UserTokenEntryDAO userTokenEntryDAO();
    public abstract LogInfoEntryDAO logInfoEntryDAO();
}