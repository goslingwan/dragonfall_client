package com.batcatstudio.dragonfall.notifications;

import java.util.HashMap;
import java.util.List;

import org.cocos2dx.lua.AppActivity;

import com.batcatstudio.dragonfall.R;
import com.batcatstudio.dragonfall.utils.DebugUtil;

import android.app.ActivityManager;
import android.app.ActivityManager.RunningAppProcessInfo;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.SystemClock;
import android.util.Log;

/**
 * Created by dannyhe on 7/27/15.
 */
public class NotificationUtils {

    private static HashMap<String, NotificationMessage> localPushInfoMap  = new HashMap<String, NotificationMessage>();
    private static String TAG = "NotificationUtils";
    public static void cancelAllLocalPush() {
        localPushInfoMap.clear();
    }

    public static boolean addLocalPush(String msgType,String alertBody,String identity,long fireTime) {
    	DebugUtil.LogDebug(TAG, "addLocalPush---->"+fireTime);
        NotificationMessage ns = new NotificationMessage(alertBody,fireTime,msgType);
        localPushInfoMap.put(identity, ns);
        return true;
    }


    public static void startLocalPushService() {
    	DebugUtil.LogDebug(TAG, "startLocalPushService----------->");
        Intent intent = getStartLocalPushIntent();
        if (intent != null) {
            AppActivity.getGameActivity().startService(intent);
        }
    }

    public static Intent getStartLocalPushIntent() {
        if (localPushInfoMap.isEmpty()) {
            return null;
        }

        int length = localPushInfoMap.keySet().size();
        String[] notificationContent = new String[length];
        long[] notificationTime = new long[length];
        int i = 0;
        for (String identity : localPushInfoMap.keySet()) {
            NotificationMessage msg = localPushInfoMap.get(identity);
            notificationContent[i] = msg.getAlertBody();
            notificationTime[i++] = msg.getFireTime();
        }

        Intent intent = new Intent(AppActivity.getGameActivity(), LocalNotificationService.class);
        intent.putExtra(LocalNotificationService.KEY_NOTIFICATION_CONTENTS, notificationContent);
        intent.putExtra(LocalNotificationService.KEY_NOTIFICATION_TIMES, notificationTime);
        return intent;
    }

    public static void stopLocalPushService() {
    	DebugUtil.LogDebug(TAG, "stopLocalPushService----------->");
        NotificationManager notificationManager = (NotificationManager) AppActivity.getGameActivity()
                .getSystemService(Context.NOTIFICATION_SERVICE);
        notificationManager.cancelAll();
        Intent intent = new Intent(AppActivity.getGameActivity(), LocalNotificationService.class);
        AppActivity.getGameActivity().stopService(intent);
    }

    public static boolean cancelNotificationWithIdentity(String identity)
    {
        DebugUtil.LogDebug(TAG, "cancelNotificationWithIdentity---->"+identity);
        NotificationMessage msg = localPushInfoMap.get(identity);
        if(msg!=null){
            localPushInfoMap.remove(identity);
             return true;
        }
         return false;
    }
    
    public static void generalGCMNotification(Context context,String msg){
    	if(AppActivity.getGameActivity() != null)return;
    	int icon = R.drawable.icon;
		long when = System.currentTimeMillis();
		CharSequence message = msg;
		NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
		Notification notification = new Notification(icon, message, when);
		String title = context.getString(R.string.app_name);

		Intent gameIntent = new Intent(context, AppActivity.class);
		
		PendingIntent intent = PendingIntent.getActivity(context, 0, gameIntent, PendingIntent.FLAG_UPDATE_CURRENT);
		notification.defaults = Notification.DEFAULT_SOUND | Notification.DEFAULT_VIBRATE;
		notification.flags |= Notification.FLAG_AUTO_CANCEL;
		notification.flags |= Notification.FLAG_SHOW_LIGHTS;
		notification.ledARGB = 0xFFFF0000;
		notification.ledOnMS = 1000;
		notification.ledOffMS = 500;
		notification.setLatestEventInfo(context, title, message, intent);
		notificationManager.notify((int) SystemClock.elapsedRealtime(), notification);
    }

}