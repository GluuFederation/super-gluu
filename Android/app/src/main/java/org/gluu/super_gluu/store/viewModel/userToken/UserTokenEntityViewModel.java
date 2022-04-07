package org.gluu.super_gluu.store.viewModel.userToken;

import android.app.Application;
import android.os.AsyncTask;

import androidx.annotation.NonNull;
import androidx.lifecycle.AndroidViewModel;

import org.gluu.super_gluu.store.entity.UserTokenEntry;
import org.gluu.super_gluu.store.repository.userToken.UserTokenEntityRepository;

import java.util.concurrent.ExecutionException;

public class UserTokenEntityViewModel extends AndroidViewModel {

    private UserTokenEntityRepository mUserTokenEntityRepository;

    public UserTokenEntityViewModel(@NonNull Application application, String applicationName, String userName) {
        super(application);

        mUserTokenEntityRepository = new UserTokenEntityRepository(application, applicationName, userName);
    }

    public UserTokenEntry getUserTokenEntity() {
        try {
            return new UserTokenSectionsTask(mUserTokenEntityRepository).execute().get();
        } catch (ExecutionException e) {
            e.printStackTrace();
            return null;
        } catch (InterruptedException e) {
            e.printStackTrace();
            return null;
        }
    }

    public void deleteEntity() {
        AsyncTask.execute(() -> mUserTokenEntityRepository.delete());
    }

    private static class UserTokenSectionsTask extends AsyncTask<Void, Void, UserTokenEntry> {

        private UserTokenEntityRepository mUserTokenEntityRepository;

        UserTokenSectionsTask(UserTokenEntityRepository userTokenEntityRepository) {
            mUserTokenEntityRepository = userTokenEntityRepository;
        }

        @Override
        protected UserTokenEntry doInBackground(Void... notes) {
            return mUserTokenEntityRepository.getUserTokenEntity();
        }
    }
}
