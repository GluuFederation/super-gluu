package org.gluu.super_gluu.store.viewModel.userToken;

import android.app.Application;
import android.os.AsyncTask;

import androidx.annotation.NonNull;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;

import org.gluu.super_gluu.store.entity.UserTokenEntry;
import org.gluu.super_gluu.store.repository.userToken.UserTokenListRepository;

import java.util.List;
import java.util.concurrent.ExecutionException;

public class UserTokenEntityListViewModel extends AndroidViewModel {

    private UserTokenListRepository mUserTokenEntityRepository;

    public UserTokenEntityListViewModel(@NonNull Application application) {
        super(application);

        mUserTokenEntityRepository = new UserTokenListRepository(application);
    }

    public LiveData<List<UserTokenEntry>> getUserTokenEntityList() {
        return mUserTokenEntityRepository.getAllEntity();
    }
}
