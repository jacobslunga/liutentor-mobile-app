//
//  MathContentWebView.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-28.
//

import SwiftUI
import WebKit

/// A WebView that renders Markdown with KaTeX math, sized to its content height.
///
/// The HTML shell (marked + KaTeX + CSS) is loaded once. Subsequent content
/// updates are pushed via `window.updateContent(text)` so streaming chunks can
/// re-render in place without reloading the page — KaTeX auto-render skips
/// incomplete `$$...$$` blocks, so partial math just appears as raw text until
/// the closing delimiter streams in.
struct MathContentWebView: UIViewRepresentable {
    let markdownContent: String
    let isDark: Bool
    @Binding var contentHeight: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "heightHandler")
        controller.add(context.coordinator, name: "readyHandler")

        let config = WKWebViewConfiguration()
        config.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        let coord = context.coordinator

        // Theme change (or first run) -> reload the shell. Pending content
        // will be sent once the new shell signals ready.
        if coord.lastIsDark != isDark {
            coord.lastIsDark = isDark
            coord.lastContent = ""
            coord.pageReady = false
            coord.pendingContent = markdownContent
            webView.loadHTMLString(
                Self.buildHTML(isDark: isDark),
                baseURL: URL(string: "https://cdn.jsdelivr.net/")
            )
            return
        }

        // Same theme — push content updates via JS.
        guard coord.lastContent != markdownContent else { return }
        coord.lastContent = markdownContent
        coord.apply(content: markdownContent, to: webView)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        let ucc = uiView.configuration.userContentController
        ucc.removeScriptMessageHandler(forName: "heightHandler")
        ucc.removeScriptMessageHandler(forName: "readyHandler")
    }

    // MARK: - HTML generation

    private static func buildHTML(isDark: Bool) -> String {
        let fgColor = isDark ? "#e5e5e5" : "#111111"
        let codeBg = isDark ? "#2c2c2e" : "#f2f2f2"
        let borderColor = isDark ? "#3a3a3c" : "#e0e0e0"
        let mutedColor = isDark ? "#aeaeb2" : "#636366"
        let scrollThumb = isDark ? "rgba(255,255,255,.25)" : "rgba(0,0,0,.2)"

        return """
            <!DOCTYPE html>
            <html>
            <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css">
            <style>
            *{box-sizing:border-box}
            html,body{margin:0;padding:0;background:transparent;-webkit-text-size-adjust:100%}
            body{
              font-family:-apple-system,BlinkMacSystemFont,"SF Pro Text","Helvetica Neue",sans-serif;
              font-size:15px;line-height:1.6;
              color:\(fgColor);
              overflow-x:hidden;overflow-y:visible;
              word-break:break-word;overflow-wrap:break-word
            }
            h1,h2,h3,h4,h5,h6{font-weight:600;margin:.8em 0 .3em;line-height:1.3}
            h1{font-size:1.4em}h2{font-size:1.2em}h3{font-size:1.05em}h4{font-size:1em}
            p{margin:.4em 0}
            p:first-child{margin-top:0}
            p:last-child{margin-bottom:0}
            code{
              font-family:"SF Mono",Menlo,"Courier New",monospace;
              font-size:.85em;background:\(codeBg);
              padding:.15em .35em;border-radius:4px
            }
            pre{background:\(codeBg);padding:12px;border-radius:8px;overflow-x:auto;margin:.5em 0}
            pre code{background:transparent;padding:0;font-size:.88em}
            ul,ol{margin:.4em 0;padding-left:1.5em}
            li{margin:.1em 0}
            blockquote{margin:.4em 0;padding-left:.75em;border-left:3px solid \(borderColor);color:\(mutedColor)}
            hr{border:none;border-top:1px solid \(borderColor);margin:.75em 0}
            strong{font-weight:600}
            table{border-collapse:collapse;width:100%;margin:.5em 0}
            th,td{padding:.3em .5em;border:1px solid \(borderColor);text-align:left}
            th{font-weight:600}
            .katex-display{overflow-x:auto;overflow-y:hidden;padding:.25em 0;margin:.4em 0}
            .katex-display>.katex{max-width:none;white-space:normal}
            .katex-display::-webkit-scrollbar{height:3px}
            .katex-display::-webkit-scrollbar-thumb{background:\(scrollThumb);border-radius:2px}
            .katex-display::-webkit-scrollbar-track{background:transparent}
            </style>
            </head>
            <body>
            <div id="root"></div>
            <script src="https://cdn.jsdelivr.net/npm/marked@12.0.0/marked.min.js"></script>
            <script src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js"></script>
            <script src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js"></script>
            <script>
            (function(){
              var root=document.getElementById('root');
              var lastReportedHeight=-1;

              function reportHeight(){
                var h=Math.ceil(root.getBoundingClientRect().height)||root.scrollHeight||1;
                if(h===lastReportedHeight)return;
                lastReportedHeight=h;
                try{window.webkit.messageHandlers.heightHandler.postMessage(h);}catch(e){}
              }

              window.updateContent=function(text){
                try{
                  root.innerHTML=marked.parse(text,{breaks:false,gfm:true});
                  renderMathInElement(root,{
                    delimiters:[
                      {left:'$$',right:'$$',display:true},
                      {left:'$',right:'$',display:false}
                    ],
                    throwOnError:false,strict:false
                  });
                }catch(e){
                  root.textContent=text;
                }
                reportHeight();
                setTimeout(reportHeight,50);
              };

              try{window.webkit.messageHandlers.readyHandler.postMessage(true);}catch(e){}
            })();
            </script>
            </body>
            </html>
            """
    }

    static func jsonEncode(_ string: String) -> String {
        // JSONEncoder handles top-level scalars (unlike JSONSerialization,
        // which requires an array/dict root) and escapes control chars correctly.
        if let data = try? JSONEncoder().encode(string),
            let json = String(data: data, encoding: .utf8)
        {
            return json
        }
        return "\"\""
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKScriptMessageHandler,
        WKNavigationDelegate
    {
        var parent: MathContentWebView
        var lastContent: String = ""
        var lastIsDark: Bool?
        var pageReady: Bool = false
        var pendingContent: String?

        init(_ parent: MathContentWebView) {
            self.parent = parent
        }

        func apply(content: String, to webView: WKWebView) {
            if !pageReady {
                // Latest pending wins — page-ready handler will send it.
                pendingContent = content
                return
            }
            send(content: content, to: webView)
        }

        private func send(content: String, to webView: WKWebView) {
            let json = MathContentWebView.jsonEncode(content)
            webView.evaluateJavaScript("window.updateContent(\(json));", completionHandler: nil)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            switch message.name {
            case "heightHandler":
                guard let raw = message.body as? NSNumber else { return }
                let height = CGFloat(raw.doubleValue)
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    if abs(self.parent.contentHeight - height) > 1 {
                        self.parent.contentHeight = height
                    }
                }

            case "readyHandler":
                pageReady = true
                if let pending = pendingContent, let webView = message.webView {
                    pendingContent = nil
                    send(content: pending, to: webView)
                }

            default:
                break
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
                let url = navigationAction.request.url
            {
                decisionHandler(.cancel)
                UIApplication.shared.open(url)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
