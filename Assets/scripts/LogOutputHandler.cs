using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

public class LogOutputHandler : MonoBehaviour {
	void Awake(){
#if UNITY_EDITOR
		Application.logMessageReceived += HandleLog;
#endif
	} 

	StreamWriter writer = null;

	//Capture debug.log output, send logs to Loggly
	public void HandleLog(string logString, string stackTrace, LogType type) {
#if UNITY_EDITOR
		if (writer == null) {
			writer = new StreamWriter(File.Open("sgk.log", FileMode.Create));
		}

		if (writer != null) {
			writer.WriteLine(logString);
		}
#endif
	}

	void OnDestroy() {
		if (writer != null) {
			writer.Close();
		}
        Application.logMessageReceived -= HandleLog;

    }
}