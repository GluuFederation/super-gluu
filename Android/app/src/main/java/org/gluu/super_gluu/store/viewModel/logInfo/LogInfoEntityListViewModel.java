package org.gluu.super_gluu.store.viewModel.logInfo;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;

import org.gluu.super_gluu.store.entity.LogInfoEntry;
import org.gluu.super_gluu.store.repository.logInfo.LogInfoListRepository;

import java.util.List;

public class LogInfoEntityListViewModel extends AndroidViewModel {

    private LogInfoListRepository mLogInfoEntityRepository;

    public LogInfoEntityListViewModel(@NonNull Application application) {
        super(application);

        mLogInfoEntityRepository = new LogInfoListRepository(application);
    }

    public LiveData<List<LogInfoEntry>> getLogInfoEntityList() {
        return mLogInfoEntityRepository.getAllEntity();
    }
}
