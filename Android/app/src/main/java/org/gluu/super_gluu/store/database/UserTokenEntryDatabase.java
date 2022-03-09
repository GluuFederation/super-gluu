package org.gluu.super_gluu.store.database;

import android.content.Context;
import android.os.AsyncTask;
import android.util.Log;

import androidx.room.Database;
import androidx.room.Room;
import androidx.room.RoomDatabase;

import com.google.gson.Gson;

import org.gluu.super_gluu.store.AndroidKeyDataStore;
import org.gluu.super_gluu.store.dao.UserTokenEntryDAO;
import org.gluu.super_gluu.store.entity.UserTokenEntry;
import org.gluu.super_gluu.u2f.v2.model.TokenEntry;

import java.util.ArrayList;
import java.util.List;

@Database(entities = UserTokenEntry.class, exportSchema = false, version = 1)
public abstract class UserTokenEntryDatabase extends RoomDatabase {

    private static final String DB_NAME = "user_token_entry_db";
    private static UserTokenEntryDatabase instance;
    private static AndroidKeyDataStore androidKeyDataStore;

    public static synchronized UserTokenEntryDatabase getInstance(Context context) {
        if (instance == null) {
            instance = Room.databaseBuilder(
                    context.getApplicationContext(),
                    UserTokenEntryDatabase.class,
                    DB_NAME
            ).fallbackToDestructiveMigration().build();
        }

        androidKeyDataStore = new AndroidKeyDataStore(context);

        return instance;
    }

    public abstract UserTokenEntryDAO userTokenEntryDAO();

    // Method for migration all data from SharedPreferences to Database
    public void migrateDataIfNeeded() {
        // Migration flow:
        // 1. Check were all data migrated or not yet
        boolean isMigrationAlreadyDone = androidKeyDataStore.getMigrationStatus();
        if (isMigrationAlreadyDone) {
            AsyncTask.execute(new Runnable() {
                @Override
                public void run() {
                    List<UserTokenEntry> tokenEntryList = instance.userTokenEntryDAO().getAll();
                }
            });
            return;
        }
        // 2. Try to move all TokenEntries to DB
        List<String> tokens = androidKeyDataStore.getTokenEntries();
        for (String token: tokens) {
            TokenEntry tokenEntry = new Gson().fromJson(token, TokenEntry.class);
            UserTokenEntry userTokenEntry = new UserTokenEntry(tokenEntry);
            AsyncTask.execute(new Runnable() {
                @Override
                public void run() {
                    try {
                        instance.userTokenEntryDAO().insert(userTokenEntry);
                    } catch (Exception exception) {
                        Log.i("UserTokenEntryDatabase", exception.getMessage());
                    }

                }
            });
        }
        // 3. Mark migration status as Done
        androidKeyDataStore.setMigrationStatus(true);
    }
}