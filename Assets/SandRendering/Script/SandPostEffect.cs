using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SandPostEffect : MonoBehaviour {

	public Material mat;
	public Texture fogColorTexture;
	[Range(0,1f)]
	public float fogNear;
	[Range(0,1f)]
	public float fogFar;

	// Use this for initialization
	void Start () {
		var cam = GetComponent<Camera> ();
		cam.depthTextureMode = DepthTextureMode.Depth;
	}

	void OnRenderImage( RenderTexture source , RenderTexture target ) {
		if (mat != null) {
			mat.SetTexture ("_FogColorTex", fogColorTexture);
			mat.SetFloat ("_FogNear", fogNear);
			mat.SetFloat ("_FogFar", fogFar);

			Graphics.Blit (source, target, mat);
		}
	}
}
