using UnityEngine;
using UnityEditor;
using System.Collections;

namespace BeautifyEffect
{
	[CustomEditor(typeof(Beautify))]
	public class BeautifyEffectInspector : Editor
	{

		Beautify _effect;
		Texture2D _headerTexture;
		GUIStyle titleLabelStyle;
		Color titleColor;

		void OnEnable ()
		{
			titleColor = EditorGUIUtility.isProSkin ? new Color (0.52f, 0.66f, 0.9f) : new Color (0.12f, 0.16f, 0.4f);
			_headerTexture = Resources.Load<Texture2D> ("beautifyHeader");
			_effect = (Beautify)target;
		}

		public override void OnInspectorGUI ()
		{
			if (_effect == null)
				return;
			_effect.isDirty = false;

			EditorGUILayout.Separator ();
			GUI.skin.label.alignment = TextAnchor.MiddleCenter;  
			GUILayout.Label (_headerTexture, GUILayout.ExpandWidth (true));
			GUI.skin.label.alignment = TextAnchor.MiddleLeft;  

			EditorGUILayout.BeginHorizontal ();
			DrawLabel ("General Settings");
			if (GUILayout.Button ("Help", GUILayout.Width (50))) {
				EditorUtility.DisplayDialog ("Help", "Beautify is a full-screen image processing effect that makes your scenes crisp, vivid and intense.\n\nMove the mouse over a setting for a short description.\nVisit kronnect.com for support and questions.\n\nPlease rate Beautify on the Asset Store! Thanks.", "Ok");
			}
			EditorGUILayout.EndHorizontal ();

			EditorGUILayout.BeginHorizontal ();
			GUILayout.Label (new GUIContent ("Quality", "The mobile variant is simply less accurate but faster."), GUILayout.Width (90));
			_effect.quality = (BEAUTIFY_QUALITY)EditorGUILayout.EnumPopup (_effect.quality);
			EditorGUILayout.EndHorizontal ();

			EditorGUILayout.BeginHorizontal ();
			GUILayout.Label (new GUIContent ("Preset", "Quick configurations."), GUILayout.Width (90));
			_effect.preset = (BEAUTIFY_PRESET)EditorGUILayout.EnumPopup (_effect.preset);
			EditorGUILayout.EndHorizontal ();
			
			EditorGUILayout.BeginHorizontal ();
			GUILayout.Label (new GUIContent ("Compare Mode", "Shows a side by side comparison."), GUILayout.Width (90));
			_effect.compareMode = EditorGUILayout.Toggle (_effect.compareMode);
			EditorGUILayout.EndHorizontal ();

			EditorGUILayout.Separator ();
			DrawLabel ("Image Enhancement");

			EditorGUILayout.BeginHorizontal ();
			GUILayout.Label (new GUIContent ("Sharpen", "Sharpen intensity."), GUILayout.Width (90));
			_effect.sharpen = EditorGUILayout.Slider (_effect.sharpen, 0, 10);
			EditorGUILayout.EndHorizontal ();

			EditorGUILayout.BeginHorizontal ();
			GUILayout.Label (new GUIContent ("   Min/Max Depth", "Any pixel outside this depth range won't be affected by sharpen. Reduce range to create a depth-of-field-like effect."), GUILayout.Width (120));
			float minDepth = _effect.sharpenMinDepth;
			float maxDepth = _effect.sharpenMaxDepth;
			EditorGUILayout.MinMaxSlider (ref minDepth, ref maxDepth, 0, 1.1f);
			_effect.sharpenMinDepth = minDepth;
			_effect.sharpenMaxDepth = maxDepth;
			EditorGUILayout.EndHorizontal ();

			EditorGUILayout.BeginHorizontal ();
			GUILayout.Label (new GUIContent ("   Depth Threshold", "Reduces sharpen if depth difference around a pixel exceeds this value. Useful to prevent artifacts around wires or thin objects."), GUILayout.Width (120));
			_effect.sharpenDepthThreshold = EditorGUILayout.Slider (_effect.sharpenDepthThreshold, 0, 0.05f);
			EditorGUILayout.EndHorizontal ();

			EditorGUILayout.BeginHorizontal ();
			GUILayout.Label (new GUIContent ("   Luminance Relax.", "Soften sharpen around a pixel with high contrast. Reduce this value to remove ghosting and protect fine drawings or wires over a flat surface."), GUILayout.Width (120));
			_effect.sharpenRelaxation = EditorGUILayout.Slider (_effect.sharpenRelaxation, 0, 0.2f);
			EditorGUILayout.EndHorizontal ();

			EditorGUILayout.BeginHorizontal ();
			GUILayout.Label (new GUIContent ("   Clamp", "Maximum pixel adjustment."), GUILayout.Width (120));
			_effect.sharpenClamp = EditorGUILayout.Slider (_effect.sharpenClamp, 0, 1f);
			EditorGUILayout.EndHorizontal ();
			
			EditorGUILayout.BeginHorizontal ();
			GUILayout.Label (new GUIContent ("   Motion Sensibility", "Increase to reduce sharpen to simulate a cheap motion blur and to reduce flickering when camera rotates or moves. This slider controls the amount of camera movement/rotation that contributes to sharpen reduction. Set this to 0 to disable this feature."), GUILayout.Width (120));
			_effect.sharpenMotionSensibility = EditorGUILayout.Slider (_effect.sharpenMotionSensibility, 0, 1f);
			EditorGUILayout.EndHorizontal ();

			EditorGUILayout.BeginHorizontal ();
			GUILayout.Label (new GUIContent ("Dither", "Simulates more colors than RGB quantization can produce. Removes banding artifacts in gradients, like skybox. This setting controls the dithering strength."), GUILayout.Width (90));
			_effect.dither = EditorGUILayout.Slider (_effect.dither, 0, 0.2f);
			EditorGUILayout.EndHorizontal ();
	
			EditorGUILayout.BeginHorizontal ();
			GUILayout.Label (new GUIContent ("   Min Depth", "Will only remove bands on pixels beyond this depth. Useful if you only want to remove sky banding (set this to 0.99)"), GUILayout.Width (120));
			_effect.ditherDepth = EditorGUILayout.Slider (_effect.ditherDepth, 0, 1f);
			EditorGUILayout.EndHorizontal ();

			if (_effect.cameraEffect != null && !_effect.cameraEffect.hdr) {
				EditorGUILayout.BeginHorizontal ();
				DrawLabel ("   Note: dither works better with HDR enabled.");
				EditorGUILayout.EndHorizontal ();
			}

			EditorGUILayout.Separator ();
			DrawLabel ("Color Grading");

			EditorGUILayout.BeginHorizontal ();
			GUILayout.Label (new GUIContent ("Vibrance", "Improves pixels color depending on their saturation."), GUILayout.Width (90));
			_effect.saturate = EditorGUILayout.Slider (_effect.saturate, -2f, 3f);
			EditorGUILayout.EndHorizontal ();

			EditorGUILayout.BeginHorizontal ();
			GUILayout.Label (new GUIContent ("Daltonize", "Similar to vibrance but mostly accentuate primary red, green and blue colors to compensate protanomaly (red deficiency), deuteranomaly (green deficiency) and tritanomaly (blue deficiency). This effect does not shift color hue hence it won't help completely red, green or blue color blindness. The effect will vary depending on each subject so this effect should be enabled on user demand."), GUILayout.Width (90));
			_effect.daltonize = EditorGUILayout.Slider (_effect.daltonize, 0, 2f);
			EditorGUILayout.EndHorizontal ();

			EditorGUILayout.BeginHorizontal ();
			GUILayout.Label (new GUIContent ("Contrast", "Final image contrast adjustment. Allows you to create more vivid images."), GUILayout.Width (90));
			_effect.contrast = EditorGUILayout.Slider (_effect.contrast, 0.5f, 1.5f);
			EditorGUILayout.EndHorizontal ();

			EditorGUILayout.BeginHorizontal ();
			GUILayout.Label (new GUIContent ("Brightness", "Final image brightness adjustment."), GUILayout.Width (90));
			_effect.brightness = EditorGUILayout.Slider (_effect.brightness, 0f, 2f);
			EditorGUILayout.EndHorizontal ();


			if (_effect.isDirty) {
				EditorUtility.SetDirty (target);
			}


		}

		void DrawLabel (string s)
		{
			if (titleLabelStyle == null) {
				titleLabelStyle = new GUIStyle (GUI.skin.label);
			}
			titleLabelStyle.normal.textColor = titleColor;
			GUILayout.Label (s, titleLabelStyle);
		}

	}

}
