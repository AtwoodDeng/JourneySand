using UnityEngine;
using System;
using System.Collections;

namespace BeautifyEffect
{

	public enum BEAUTIFY_QUALITY {
		Desktop,
		Mobile
	}

	public enum BEAUTIFY_PRESET {
		Disabled = 0,
		Soft = 10,
		Medium = 20,
		Strong = 30,
		Exaggerated = 40,
		Custom = 999
	}

	[ExecuteInEditMode]
	[RequireComponent(typeof(Camera))]
	public class Beautify : MonoBehaviour
	{
		[SerializeField]
		BEAUTIFY_PRESET _preset = BEAUTIFY_PRESET.Medium;
		public BEAUTIFY_PRESET preset {
			get { return _preset; }
			set { if (_preset!=value) { _preset = value; UpdateMaterialProperties(); isDirty = true; } }
		}

		[SerializeField]
		BEAUTIFY_QUALITY _quality = BEAUTIFY_QUALITY.Desktop;
		public BEAUTIFY_QUALITY quality {
			get { return _quality; }
			set { if (_quality!=value) { _quality = value; UpdateMaterialProperties(); isDirty = true; } }
		}

		[SerializeField]
		bool _compareMode = false;
		public bool compareMode {
			get { return _compareMode; }
			set { if (_compareMode!=value) { _compareMode = value; UpdateMaterialProperties(); isDirty = true; } }
		}


		[SerializeField]
		float _sharpenMinDepth = 0f;
		public float sharpenMinDepth {
			get { return _sharpenMinDepth; }
			set { if (_sharpenMinDepth!=value) { _sharpenMinDepth = value; UpdateMaterialProperties(); isDirty = true; } }
		}

		[SerializeField]
		float _sharpenMaxDepth = 1.1f;
		public float sharpenMaxDepth {
			get { return _sharpenMaxDepth; }
			set { if (_sharpenMaxDepth!=value) { _sharpenMaxDepth = value; UpdateMaterialProperties(); isDirty = true; } }
		}

		[SerializeField]
		float _sharpen = 2f;
		public float sharpen {
			get { return _sharpen; }
			set { if (_sharpen!=value) { _preset = BEAUTIFY_PRESET.Custom; _sharpen = value; UpdateMaterialProperties(); isDirty = true; } }
		}
		
		[SerializeField]
		float _sharpenDepthThreshold = 0.035f;
		public float sharpenDepthThreshold {
			get { return _sharpenDepthThreshold; }
			set { if (_sharpenDepthThreshold!=value) { _preset = BEAUTIFY_PRESET.Custom; _sharpenDepthThreshold = value; UpdateMaterialProperties(); isDirty = true; } }
		}

        [SerializeField]
        float _sharpenRelaxation = 0.08f;
        public float sharpenRelaxation
        {
            get { return _sharpenRelaxation; }
            set { if (_sharpenRelaxation != value) { _preset = BEAUTIFY_PRESET.Custom; _sharpenRelaxation = value; UpdateMaterialProperties(); isDirty = true; } }
        }

        [SerializeField]
		float _sharpenClamp = 0.45f;
		public float sharpenClamp {
			get { return _sharpenClamp; }
			set { if (_sharpenClamp!=value) { _preset = BEAUTIFY_PRESET.Custom; _sharpenClamp = value; UpdateMaterialProperties(); isDirty = true; } }
		}

		[SerializeField]
		float _sharpenMotionSensibility = 0.5f;
		public float sharpenMotionSensibility {
			get { return _sharpenMotionSensibility; }
			set { if (_sharpenMotionSensibility!=value) { _sharpenMotionSensibility = value; UpdateMaterialProperties(); isDirty = true; } }
		}

		[SerializeField]
		float _saturate = 1f;
		public float saturate {
			get { return _saturate; }
			set { if (_saturate!=value) { _preset = BEAUTIFY_PRESET.Custom; _saturate = value; UpdateMaterialProperties(); isDirty = true; } }
		}

		[SerializeField]
		float _contrast = 1.02f;
		public float contrast {
			get { return _contrast; }
			set { if (_contrast!=value) { _preset = BEAUTIFY_PRESET.Custom; _contrast = value; UpdateMaterialProperties(); isDirty = true; } }
		}
		
		[SerializeField]
		float _brightness = 1.05f;
		public float brightness {
			get { return _brightness; }
			set { if (_brightness!=value) { _preset = BEAUTIFY_PRESET.Custom; _brightness = value; UpdateMaterialProperties(); isDirty = true; } }
		}

		[SerializeField]
		float _dither = 0.02f;
		public float dither {
			get { return _dither; }
			set { if (_dither!=value) { _preset = BEAUTIFY_PRESET.Custom;  _dither = value; UpdateMaterialProperties(); isDirty = true; } }
		}

		[SerializeField]
		float _ditherDepth = 0f;
		public float ditherDepth {
			get { return _ditherDepth; }
			set { if (_ditherDepth!=value) { _preset = BEAUTIFY_PRESET.Custom; _ditherDepth = value; UpdateMaterialProperties(); isDirty = true; } }
		}

		[SerializeField]
		float _daltonize = 0f;
		public float daltonize {
			get { return _daltonize; }
			set { if (_daltonize!=value) { _preset = BEAUTIFY_PRESET.Custom; _daltonize = value; UpdateMaterialProperties(); isDirty = true; } }
		}


		public bool isDirty;

		static Beautify _beautify;
		public static Beautify instance { 
			get { 
				if (_beautify==null) {
					foreach (Camera camera in Camera.allCameras) {
						_beautify = camera.GetComponent<Beautify>();
						if (_beautify!=null) break;
					}
				}
				return _beautify;
			} 
		}

		public Camera cameraEffect { get { return currentCamera; } }


		Material bMat;
		Camera currentCamera;
		Vector3 camPrevForward, camPrevPos;
		float currSens;
		int renderPass;


		#region Game loop events

		// Creates a private material used to the effect
		void OnEnable ()
		{
			bMat = Instantiate (Resources.Load<Material> ("Materials/Beautify"));
			bMat.hideFlags = HideFlags.DontSave;
			currentCamera = GetComponent<Camera>();
			if (currentCamera.depthTextureMode == DepthTextureMode.None) {
				currentCamera.depthTextureMode = DepthTextureMode.Depth;
			}
			UpdateMaterialProperties();
		}

		void OnDisable() {
			if (bMat!=null) {
				DestroyImmediate(bMat);
				bMat = null;
			}
		}

		void Reset() {
			UpdateMaterialProperties();
			isDirty = true;
		}

		void LateUpdate() {
			if (bMat==null || !Application.isPlaying || _sharpenMotionSensibility<=0) return;
			
			float angleDiff = Vector3.Angle(camPrevForward, cameraEffect.transform.forward) * _sharpenMotionSensibility;
			float posDiff = (cameraEffect.transform.position - camPrevPos).sqrMagnitude * 10f * _sharpenMotionSensibility;
			
			float diff = angleDiff + posDiff;
			if (diff>0.1f) {
				camPrevForward = cameraEffect.transform.forward;
				camPrevPos = cameraEffect.transform.position;
				if (diff > _sharpenMotionSensibility) diff =  _sharpenMotionSensibility;
				currSens += diff;
				float min = _sharpen * _sharpenMotionSensibility * 0.75f;
				float max = _sharpen * (1f + _sharpenMotionSensibility) * 0.5f;
				currSens = Mathf.Clamp(currSens, min, max);
			} else {
				if (currSens<=0.001f) return;
				currSens *= 0.75f;
			}
			float tempSharpen = Mathf.Clamp(_sharpen - currSens, 0, _sharpen);
			UpdateSharpenParams(tempSharpen);
		}

		// Postprocess the image
		void OnRenderImage (RenderTexture source, RenderTexture destination)
		{
			if (bMat==null || _preset == BEAUTIFY_PRESET.Disabled) {
				Graphics.Blit (source, destination);
				return;
			}
			Graphics.Blit(source, destination, bMat, renderPass);
		}

		#endregion



		#region Settings stuff

		void UpdateMaterialProperties() {
			switch(_preset) {
			case BEAUTIFY_PRESET.Soft:
				_sharpen = 2.0f;
				_sharpenDepthThreshold = 0.035f;
                _sharpenRelaxation = 0.065f;
                _sharpenClamp = 0.4f;
				_saturate = 0.5f;
				_contrast = 1.005f;
				_brightness = 1.05f;
				_dither = 0.02f;
				_ditherDepth = 0;
				_daltonize = 0;
				break;
			case BEAUTIFY_PRESET.Medium:
				_sharpen = 3f;
				_sharpenDepthThreshold = 0.035f;
                _sharpenRelaxation = 0.07f;
                _sharpenClamp = 0.45f;
				_saturate = 1.0f;
				_contrast = 1.02f;
				_brightness = 1.05f;
				_dither = 0.02f;
				_ditherDepth = 0;
				_daltonize = 0;
				break;
			case BEAUTIFY_PRESET.Strong:
				_sharpen = 4.75f;
				_sharpenDepthThreshold = 0.035f;
                _sharpenRelaxation = 0.075f;
                _sharpenClamp = 0.5f;
				_saturate = 1.5f;
				_contrast = 1.03f;
				_brightness = 1.05f;
				_dither = 0.022f;
				_ditherDepth = 0;
				_daltonize = 0;
				break;
			case BEAUTIFY_PRESET.Exaggerated:
				_sharpen = 7f;
				_sharpenDepthThreshold = 0.035f;
                _sharpenRelaxation = 0.08f;
                _sharpenClamp = 0.55f;
				_saturate = 2.25f;
				_contrast = 1.035f;
				_brightness = 1.05f;
				_dither = 0.025f;
				_ditherDepth = 0;
				_daltonize = 0;
				break;
			}
			if (bMat==null) return;
			UpdateSharpenParams(_sharpen);
			bMat.SetVector("_Dither", new Vector4(_dither, _ditherDepth, (_sharpenMaxDepth + _sharpenMinDepth) * 0.5f, Mathf.Abs(_sharpenMaxDepth -_sharpenMinDepth) * 0.5f));
			float cont = QualitySettings.activeColorSpace == ColorSpace.Linear ? 1.0f + (_contrast - 1.0f) / 2.2f: _contrast;
			bMat.SetVector("_ColorBoost", new Vector4(_brightness, cont, _saturate, _daltonize * 10f));

			renderPass = _quality == BEAUTIFY_QUALITY.Mobile ? 4: 0;
			if (!_compareMode) renderPass += 2;
			if (_daltonize>0) renderPass++;

		}

		void UpdateSharpenParams(float sharpen) {
			bMat.SetVector("_Sharpen", new Vector4(sharpen, _sharpenDepthThreshold, _sharpenClamp, _sharpenRelaxation));
		}

		#endregion
	
	}

}