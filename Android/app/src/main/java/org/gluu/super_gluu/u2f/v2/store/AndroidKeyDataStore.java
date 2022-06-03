/*
 *  oxPush2 is available under the MIT License (2008). See http://opensource.org/licenses/MIT for full text.
 *
 *  Copyright (c) 2014, Gluu
 */

package org.gluu.super_gluu.u2f.v2.store;

import android.app.Application;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.AsyncTask;
import android.util.Log;

import androidx.lifecycle.LifecycleOwner;
import androidx.lifecycle.LiveData;

import com.google.gson.Gson;

import org.apache.commons.codec.DecoderException;
import org.apache.commons.codec.binary.StringUtils;
import org.gluu.super_gluu.app.LogState;
import org.gluu.super_gluu.app.model.LogInfo;
import org.gluu.super_gluu.app.settings.Settings;
import org.gluu.super_gluu.model.OxPush2Request;
import org.gluu.super_gluu.store.database.UserTokenEntryDatabase;
import org.gluu.super_gluu.store.entity.LogInfoEntry;
import org.gluu.super_gluu.store.entity.UserTokenEntry;
import org.gluu.super_gluu.store.viewModel.logInfo.LogInfoEntityListViewModel;
import org.gluu.super_gluu.store.viewModel.userToken.UserTokenEntityListViewModel;
import org.gluu.super_gluu.store.viewModel.userToken.UserTokenEntityViewModel;
import org.gluu.super_gluu.u2f.v2.model.TokenEntry;
import org.gluu.super_gluu.util.Utils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.UUID;

import SuperGluu.app.BuildConfig;

/**
 * Provides methods to store key pair in application preferences
 *
 * Created by Yuriy Movchan on 12/28/2015.
 */
public class AndroidKeyDataStore implements DataStore {

    public static final String U2F_KEY_PAIR_FILE = "u2f_key_pairs";
    public static final String U2F_KEY_COUNT_FILE = "u2f_key_counts";
    public static final String LOGS_STORE = "logs_store";

    private static final String MIGRATION_STORE = "migration_store";
    private static final String MIGRATION_KEY = "migration_key";

    private static final String TAG = "key-data-store";
    private final Context context;
    private final Application application;

    private UserTokenEntityViewModel userTokenEntityViewModel;
    private UserTokenEntityListViewModel userTokenEntityListViewModel;
    private LogInfoEntityListViewModel logInfoEntityListViewModel;
    private boolean isDataBaseUsage = true;

    public UserTokenEntryDatabase database;

    public AndroidKeyDataStore(Application application) {
        this.application = application;
        this.context = application.getApplicationContext();

        database = UserTokenEntryDatabase.getInstance(application);
        userTokenEntityListViewModel = new UserTokenEntityListViewModel(application);
        logInfoEntityListViewModel = new LogInfoEntityListViewModel(application);

        // Prepare empty U2F key pair store
        final SharedPreferences keySettings = context.getSharedPreferences(U2F_KEY_PAIR_FILE, Context.MODE_PRIVATE);
        if (keySettings.getAll().size() == 0) {
            if (BuildConfig.DEBUG) Log.d(TAG, "Creating empty U2K key pair store");
            keySettings.edit().commit();
        }

        // Prepare empty U2F key counter store
        final SharedPreferences keyCounts = context.getSharedPreferences(U2F_KEY_COUNT_FILE, Context.MODE_PRIVATE);
        if (keyCounts.getAll().size() == 0) {
            if (BuildConfig.DEBUG) Log.d(TAG, "Creating empty U2K key counter store");
            keyCounts.edit().commit();
        }
    }

    @Override
    public void storeTokenEntry(TokenEntry tokenEntry) {
        if (isDataBaseUsage) {
            UserTokenEntry userTokenEntry = new UserTokenEntry(tokenEntry, 0);
            AsyncTask.execute(new Runnable() {
                @Override
                public void run() {
                    database.userTokenEntryDAO().insert(userTokenEntry);
                }
            });
            return;
        }

        Boolean isSave = true;
        List<String> tokens = getTokenListFromOldStorage();
        for (String tokenStr : tokens){
            TokenEntry token = new Gson().fromJson(tokenStr, TokenEntry.class);
            boolean isNameEquals = token.getUserName().equalsIgnoreCase(tokenEntry.getUserName());
            boolean isApplicationEquals = token.getApplication().equalsIgnoreCase(tokenEntry.getApplication());
            if (isNameEquals && isApplicationEquals) {
                isSave = false;
            }
        }
        if (isSave) {
            String keyHandleKey = keyHandleToKey(tokenEntry.getKeyHandle());

            final String tokenEntryString = new Gson().toJson(tokenEntry);
            if (BuildConfig.DEBUG)
                Log.d(TAG, "Storing new keyHandle: " + keyHandleKey + " with tokenEntry: " + tokenEntryString);

            final SharedPreferences keySettings = context.getSharedPreferences(U2F_KEY_PAIR_FILE, Context.MODE_PRIVATE);

            keySettings.edit().putString(keyHandleKey, tokenEntryString).commit();

            final SharedPreferences keyCounts = context.getSharedPreferences(U2F_KEY_COUNT_FILE, Context.MODE_PRIVATE);
            keyCounts.edit().putInt(keyHandleKey, 0).commit();
        }
    }

    @Override
    public TokenEntry getTokenEntry(String application, String userName) {
        if (BuildConfig.DEBUG) Log.d(TAG, "Getting keyPair by application : " + application);

        if (isDataBaseUsage) {
            userTokenEntityViewModel = new UserTokenEntityViewModel(this.application, application, userName);
            UserTokenEntry userTokenEntry = userTokenEntityViewModel.getUserTokenEntity();

            return new TokenEntry(userTokenEntry);
        }

        List<String> tokenArray = getTokenListFromOldStorage();
        for (String tokenString : tokenArray) {
            TokenEntry token = new Gson().fromJson(tokenString, TokenEntry.class);
            boolean isApplicationValid = token.getApplication().equalsIgnoreCase(application);
            boolean isUserNameValid = token.getUserName().equalsIgnoreCase(userName);
            if (isApplicationValid && isUserNameValid) {
                return token;
            }
        }

        return null;
    }

    @Override
    public int incrementCounter(String application, String userName) {
        userTokenEntityViewModel = new UserTokenEntityViewModel(this.application, application, userName);
        UserTokenEntry userTokenEntry = userTokenEntityViewModel.getUserTokenEntity();

        String keyHandleKey = keyHandleToKey(userTokenEntry.getKeyHandle());

        if (BuildConfig.DEBUG) Log.d(TAG, "Incrementing keyHandle: " + keyHandleKey + " counter");

        int currentCounter = userTokenEntry.getCounter();
        currentCounter++;

        final int finalCounter = currentCounter;
        final int finalId = userTokenEntry.getId();
        AsyncTask.execute(() -> database.userTokenEntryDAO().update(finalCounter, finalId));

        if (BuildConfig.DEBUG) Log.d(TAG, "Counter is " + currentCounter + " for keyHandle: " + keyHandleKey + " counter");

        return currentCounter;
    }

    @Override
    public int incrementCounter(byte[] keyHandle) {
        String keyHandleKey = keyHandleToKey(keyHandle);

        if (BuildConfig.DEBUG) Log.d(TAG, "Incrementing keyHandle: " + keyHandleKey + " counter");

        final SharedPreferences keyCounts = context.getSharedPreferences(U2F_KEY_COUNT_FILE, Context.MODE_PRIVATE);

        int currentCounter = keyCounts.getInt(keyHandleKey, -1);
        currentCounter++;

        keyCounts.edit().putInt(keyHandleKey, currentCounter).commit();

        if (BuildConfig.DEBUG) Log.d(TAG, "Counter is " + currentCounter + " for keyHandle: " + keyHandleKey + " counter");

        return currentCounter;
    }

    @Override
    public List<byte[]> getKeyHandlesByIssuerAndAppId(String issuer, String application) {
        List<byte[]> result = new ArrayList<>();

//        if (isDataBaseUsage) {
//            userTokenEntityListViewModel = new UserTokenEntityListViewModel(this.application);
//            List<UserTokenEntry> userTokenEntryList = userTokenEntityListViewModel.getUserTokenEntityList();
//            for (UserTokenEntry token : userTokenEntryList) {
//                result.add(token.getKeyHandle());
//            }
//            return result;
//        }

        final SharedPreferences keySettings = context.getSharedPreferences(U2F_KEY_PAIR_FILE, Context.MODE_PRIVATE);
        Map<String, String> keyTokens = (Map<String, String>) keySettings.getAll();
        for (Map.Entry<String, String> keyToken : keyTokens.entrySet()) {
            String tokenEntryString = keyToken.getValue();

            TokenEntry tokenEntry = new Gson().fromJson(tokenEntryString, TokenEntry.class);

            if (((issuer == null) || StringUtils.equals(issuer, tokenEntry.getIssuer()))
                    && ((application == null) || StringUtils.equals(application, tokenEntry.getApplication()))) {
                String keyHandleKey = keyToken.getKey();
                try {
                    byte[] keyHandle = keyToKeyHandle(keyHandleKey);
                    result.add(keyHandle);
                } catch (DecoderException ex) {
                    Log.e(TAG, "Invalid keyHandle: " + keyHandleKey, ex);
                }
            }
        }
        return result;
    }

    @Override
    public LiveData<List<UserTokenEntry>> getTokenEntries() {
        return userTokenEntityListViewModel.getUserTokenEntityList();
    }

    @Override
    public boolean doesKeyAlreadyExist(OxPush2Request oxPush2Request) {
        if (isDataBaseUsage) {
            userTokenEntityViewModel = new UserTokenEntityViewModel(this.application, oxPush2Request.getIssuer(), oxPush2Request.getUserName());
            UserTokenEntry userTokenEntry = userTokenEntityViewModel.getUserTokenEntity();

            return userTokenEntry != null;
        }

        List<String> tokensString = getTokenListFromOldStorage();
        if(tokensString == null || tokensString.isEmpty()) {
            return false;
        }

        List<TokenEntry> tokens = new ArrayList<>();
        for (String tokenString : tokensString){
            TokenEntry token = new Gson().fromJson(tokenString, TokenEntry.class);
            tokens.add(token);
        }

        for(TokenEntry tokenEntry: tokens) {
            if(tokenEntry != null && oxPush2Request != null &&
                    tokenEntry.getUserName().equals(oxPush2Request.getUserName()) &&
                    tokenEntry.getIssuer().equals(oxPush2Request.getIssuer())) {
                return true;
            }
        }

        return false;
    }

    @Override
    public void changeKeyHandleName(TokenEntry tokenEntry, String newName) {
        if (isDataBaseUsage) {
            userTokenEntityViewModel = new UserTokenEntityViewModel(this.application, tokenEntry.getApplication(), tokenEntry.getUserName());
            UserTokenEntry userTokenEntry = userTokenEntityViewModel.getUserTokenEntity();
            AsyncTask.execute(() -> database.userTokenEntryDAO().updateKeyHandleName(newName, userTokenEntry.getId()));

            return;
        }

        final SharedPreferences keySettings = context.getSharedPreferences(U2F_KEY_PAIR_FILE, Context.MODE_PRIVATE);
        Map<String, String> keyTokens = (Map<String, String>) keySettings.getAll();
        for (Map.Entry<String, String> keyToken : keyTokens.entrySet()) {
            String tokenEntryString = keyToken.getValue();

            TokenEntry tokenEntryFromDB = new Gson().fromJson(tokenEntryString, TokenEntry.class);

            if (tokenEntryFromDB.getUserName().equalsIgnoreCase(tokenEntry.getUserName()) && tokenEntryFromDB.getIssuer().equalsIgnoreCase(tokenEntry.getIssuer())){//keyHandleID != null && StringUtils.equals(keyHandleID, tokenEntry.getIssuer())
                tokenEntry.setKeyName(newName);
                SharedPreferences tokenSettings = context.getSharedPreferences(U2F_KEY_PAIR_FILE, Context.MODE_PRIVATE);
                String tokenEntryStr = new Gson().toJson(tokenEntry);
                String keyHandleKey = keyHandleToKey(tokenEntry.getKeyHandle());
                tokenSettings.edit().putString(keyHandleKey, tokenEntryStr).commit();
                return;
            }
        }
    }

    @Override
    public void deleteKeyHandle(TokenEntry tokenEntry) {
        if (isDataBaseUsage) {
            userTokenEntityViewModel = new UserTokenEntityViewModel(this.application, tokenEntry.getApplication(), tokenEntry.getUserName());
            userTokenEntityViewModel.deleteEntity();

            return;
        }

        byte[] keyHandle = tokenEntry.getKeyHandle();
        String keyHandleKey = keyHandleToKey(keyHandle);
        final SharedPreferences keySettings = context.getSharedPreferences(U2F_KEY_PAIR_FILE, Context.MODE_PRIVATE);
        final SharedPreferences keyCount = context.getSharedPreferences(U2F_KEY_COUNT_FILE, Context.MODE_PRIVATE);
        keySettings.edit().remove(keyHandleKey).commit();
        keyCount.edit().remove(keyHandleKey).commit();
    }

    public static String keyHandleToKey(byte[] keyHandle) {
        return Utils.encodeHexString(keyHandle);
    }

    public static byte[] keyToKeyHandle(String key) throws DecoderException {
        return Utils.decodeHexString(key);
    }

    //Methods for logs

    @Override
    public void saveLog(LogInfo logInfo) {
        if (isDataBaseUsage) {
            LogInfoEntry logInfoEntry = new LogInfoEntry(logInfo);
            AsyncTask.execute(() -> database.logInfoEntryDAO().insert(logInfoEntry));

            return;
        }

        final String logInfoString = new Gson().toJson(logInfo);
        final SharedPreferences logSettings = context.getSharedPreferences(LOGS_STORE, Context.MODE_PRIVATE);
        logSettings.edit().putString(UUID.randomUUID().toString(), logInfoString).commit();
    }

    @Override
    public LiveData<List<LogInfoEntry>> getLogEntity() {
        return logInfoEntityListViewModel.getLogInfoEntityList();
    }

    @Override
    public List<LogInfo> getLogs() {
        List<LogInfo> logs = new ArrayList<>();

        final SharedPreferences logSettings = context.getSharedPreferences(LOGS_STORE, Context.MODE_PRIVATE);
        Map<String, String> logsMap = (Map<String, String>) logSettings.getAll();

        for (Map.Entry<String, String> log : logsMap.entrySet()) {
            logs.add(new Gson().fromJson(log.getValue(), LogInfo.class));
        }
        return logs;
    }

    @Override
    public void deleteLogs() {
        if (isDataBaseUsage) {
            AsyncTask.execute(() -> database.logInfoEntryDAO().deleteAll());

            return;
        }
        final SharedPreferences logSettings = context.getSharedPreferences(LOGS_STORE, Context.MODE_PRIVATE);
        logSettings.edit().clear().commit();
    }
    @Override
    public void deleteLogs(List<LogInfo> logInfoList, LifecycleOwner lifecycleOwner) {
        if (isDataBaseUsage) {
            List<Integer> idList = new ArrayList<>();
            logInfoEntityListViewModel.getLogInfoEntityList().observe(lifecycleOwner, logInfoEntryList -> {
                for (LogInfo logInfo: logInfoList) {
                    for (LogInfoEntry logInfoEntry : logInfoEntryList) {
                        if (logInfo.getIssuer().equalsIgnoreCase(logInfoEntry.getIssuer()) && logInfo.getUserName().equalsIgnoreCase(logInfoEntry.getUserName())) {
                            idList.add(logInfoEntry.getId());
                        }
                    }
                }

                AsyncTask.execute(() -> database.logInfoEntryDAO().delete(idList));
            });

            return;
        }

        List<LogInfo> logsFromDB = this.getLogs();
        for (LogInfo oxPush2Request : logInfoList){
            Iterator<LogInfo> iter = logsFromDB.iterator();
            while (iter.hasNext()) {
                LogInfo logInf = iter.next();
                if (oxPush2Request.getCreatedDate().equalsIgnoreCase(logInf.getCreatedDate())) {
                    iter.remove();
                }
            }
        }
        logsFromDB.removeAll(Arrays.asList(logInfoList));
        this.deleteLogs();
        for (LogInfo logInf : logsFromDB){
            this.saveLog(logInf);
        }
    }

    // Method for migration all data from SharedPreferences to Database
    public void migrateDataIfNeeded() {
        // Migration flow:
        // 1. Check were all data migrated or not yet
        boolean isMigrationAlreadyDone = getMigrationStatus();
        if (isMigrationAlreadyDone) {
            return;
        }
        // 2. Try to move all TokenEntries to DB
        List<String> tokens = getTokenListFromOldStorage();

        for (String token: tokens) {
            TokenEntry tokenEntry = new Gson().fromJson(token, TokenEntry.class);

            String keyHandleKey = Utils.encodeHexString(tokenEntry.getKeyHandle());
            final SharedPreferences keyCounts = application.getApplicationContext().getSharedPreferences(AndroidKeyDataStore.U2F_KEY_COUNT_FILE, Context.MODE_PRIVATE);
            int counter = keyCounts.getInt(keyHandleKey, 0);

            UserTokenEntry userTokenEntry = new UserTokenEntry(tokenEntry, counter);
            AsyncTask.execute(() -> {
                try {
                    database.userTokenEntryDAO().insert(userTokenEntry);
                } catch (Exception exception) {
                    Log.i(TAG, exception.getMessage());
                }
            });
        }

        // 3. Move all Logs data to database
        // Remove it after test
        AsyncTask.execute(() -> { database.logInfoEntryDAO().deleteAll(); });
        // End
        final SharedPreferences logSettings = application.getApplicationContext().getSharedPreferences(AndroidKeyDataStore.LOGS_STORE, Context.MODE_PRIVATE);
        Map<String, String> logsMap = (Map<String, String>) logSettings.getAll();

        for (Map.Entry<String, String> log : logsMap.entrySet()) {
            LogInfo logInfo = new Gson().fromJson(log.getValue(), LogInfo.class);
            LogInfoEntry logInfoEntry = new LogInfoEntry(logInfo);
            AsyncTask.execute(() -> {
                try {
                    database.logInfoEntryDAO().insert(logInfoEntry);
                } catch (Exception exception) {
                    Log.i(TAG, exception.getMessage());
                }
            });
        }

        // 4. Mark migration status as Done
        setMigrationStatus(true);
    }

    private List<String> getTokenListFromOldStorage() {
        List<String> tokens = new ArrayList<>();

        final SharedPreferences keySettings = application.getApplicationContext().getSharedPreferences(AndroidKeyDataStore.U2F_KEY_PAIR_FILE, Context.MODE_PRIVATE);
        Map<String, String> keyTokens = (Map<String, String>) keySettings.getAll();
        for (Map.Entry<String, String> keyToken : keyTokens.entrySet()) {
            String tokenEntryString = keyToken.getValue();
            TokenEntry tokenEntry = new Gson().fromJson(tokenEntryString, TokenEntry.class);
            String keyHandleKey = keyToken.getKey();
            try {
                byte[] keyHandle = AndroidKeyDataStore.keyToKeyHandle(keyHandleKey);
                tokenEntry.setKeyHandle(keyHandle);
            } catch (DecoderException e) {
                Log.e(TAG, "Decoder exception: ", e);
            }
            tokenEntryString = new Gson().toJson(tokenEntry);
            tokens.add(tokenEntryString);
        }

        return tokens;
    }

    //Migration
    public Boolean getMigrationStatus() {
        final SharedPreferences keySettings = application.getApplicationContext().getSharedPreferences(MIGRATION_STORE, Context.MODE_PRIVATE);

        return keySettings.getBoolean(MIGRATION_KEY, false);
    }

    public void setMigrationStatus(Boolean status) {
        final SharedPreferences keySettings = application.getApplicationContext().getSharedPreferences(MIGRATION_STORE, Context.MODE_PRIVATE);
        keySettings.edit().putBoolean(MIGRATION_KEY, status).commit();
    }
}