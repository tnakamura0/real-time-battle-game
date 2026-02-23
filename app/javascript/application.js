import "@hotwired/turbo-rails"
import "controllers"
import "channels"

const renderGoogleButton = () => {
  const config = document.getElementById("custom_g_id_onload");
  const container = document.querySelector(".js_google_button");

  if (!config || !container) return;

  // Googleライブラリがロードされるのを待つ（再帰呼び出し）
  if (typeof google === "undefined" || !google.accounts.id) {
    setTimeout(renderGoogleButton, 100);
    return;
  }

  // 描画処理
  // モバイルでのガタつき防止やタブレット・PCでのボタン変化後に描画したい場合はここと下のsetTimeoutのコメントアウトを解除する
  // container.style.opacity = "0";
  container.innerHTML = "";

  google.accounts.id.initialize({
    client_id: config.dataset.gClient_id || config.dataset.gClientId,
    login_uri: config.dataset.gLogin_uri || config.dataset.gLoginUri,
    auto_prompt: false,
    itp_support: true,           
    ux_mode: 'redirect', // これをつけないとCOOPエラーが起きてログインできない
    // use_fedcm_for_prompt: false, 
  });

  const parentWidth = container.parentElement.offsetWidth;
  const finalWidth = parentWidth > 0 ? parentWidth : 300;
  
  google.accounts.id.renderButton(container, {
    type: "standard",
    size: "large",
    theme: "outline",
    text: container.dataset.text || "signin_with",
    shape: "pill",
    width: finalWidth,
    logo_alignment: "center",
    locale: "ja",
    ux_mode: 'redirect',
  });

  // setTimeout(() => {
  //   container.style.transition = "opacity 0.001s";
  //   container.style.opacity = "1";
  // }, 300);
};

document.addEventListener("turbo:load", renderGoogleButton);
document.addEventListener("turbo:render", renderGoogleButton);
