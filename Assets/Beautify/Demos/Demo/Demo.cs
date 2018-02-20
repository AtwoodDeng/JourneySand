using UnityEngine;
using System.Collections;

namespace BeautifyEffect
{
	public class Demo : MonoBehaviour
	{

		void OnGUI ()
		{
			Rect rect = new Rect (10, 10, Screen.width - 20, 30);
			GUI.Label (rect, "Move around with WASD or cursor keys, mouse to look, T or left mouse button to toggle beautify on/off.");

			rect = new Rect (10, 30, Screen.width - 20, 30);
			if (Beautify.instance.enabled) {
				GUI.Label (rect, "BEAUTIFY EFFECT ON => Crisp mountains, no banding on sky, color enhancement.");
			} else {
				GUI.Label (rect, "BEAUTIFY EFFECT OFF");
			}
		}

		void Update() {
			if (Input.GetKeyDown(KeyCode.T) || Input.GetMouseButtonDown(0)) Beautify.instance.enabled = !Beautify.instance.enabled;
		}
	}

}