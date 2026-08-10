import React from 'react';
import Head from 'next/head';

export default function SupportPage() {
  return (
    <div style={styles.container}>
      <Head>
        <title>技术支持 - Rêverie</title>
        <meta name="description" content="Rêverie 技术支持与帮助中心" />
      </Head>

      <header style={styles.header}>
        <a href="/" style={styles.backLink}>← 返回首页</a>
        <h1 style={styles.title}>技术支持</h1>
      </header>

      <main style={styles.main}>
        <div style={styles.content}>
          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>常见问题</h2>

            <div style={styles.faqItem}>
              <h3 style={styles.faqQuestion}>如何导入视频？</h3>
              <p style={styles.faqAnswer}>
                在主页面点击"导入视频"按钮，您可以从相册或文件 App 中选择视频文件。
              </p>
            </div>

            <div style={styles.faqItem}>
              <h3 style={styles.faqQuestion}>处理视频需要多长时间？</h3>
              <p style={styles.faqAnswer}>
                处理时间取决于视频长度和所选效果强度。通常 1 分钟的视频需要 30-60 秒处理时间。
              </p>
            </div>

            <div style={styles.faqItem}>
              <h3 style={styles.faqQuestion}>处理后的视频保存在哪里？</h3>
              <p style={styles.faqAnswer}>
                处理完成后，视频会自动保存到您的相册中。
              </p>
            </div>

            <div style={styles.faqItem}>
              <h3 style={styles.faqQuestion}>支持哪些视频格式？</h3>
              <p style={styles.faqAnswer}>
                支持常见的视频格式，包括 MP4、MOV、M4V 等。
              </p>
            </div>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>联系我们</h2>
            <p style={styles.contactText}>
              如果您的问题未在常见问题中找到解答，或需要进一步的技术支持，请通过以下方式联系我们：
            </p>

            <div style={styles.contactMethods}>
              <div style={styles.contactMethod}>
                <h3 style={styles.contactTitle}>电子邮件</h3>
                <a href="mailto:support@reverie-app.com" style={styles.contactLink}>
                  support@reverie-app.com
                </a>
                <p style={styles.contactNote}>我们会在 24-48 小时内回复您的邮件</p>
              </div>

              <div style={styles.contactMethod}>
                <h3 style={styles.contactTitle}>反馈表单</h3>
                <p style={styles.contactLink}>
                  <a href="https://forms.example.com/reverie-feedback" style={styles.contactLink}>
                    提交反馈
                  </a>
                </p>
                <p style={styles.contactNote}>帮助我们改进应用</p>
              </div>
            </div>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>应用信息</h2>
            <div style={styles.appInfo}>
              <p><strong>版本：</strong>1.0</p>
              <p><strong>系统要求：</strong>iOS 15.0 或更高版本</p>
              <p><strong>设备支持：</strong>iPhone、iPad</p>
              <p><strong>文件大小：</strong>约 50 MB</p>
            </div>
          </div>
        </div>
      </main>

      <footer style={styles.footer}>
        <div style={styles.footerLinks}>
          <a href="/" style={styles.footerLink}>首页</a>
          <a href="/privacy" style={styles.footerLink}>隐私政策</a>
          <a href="/terms" style={styles.footerLink}>使用条款</a>
        </div>
        <p style={styles.copyright}>© 2024 Rêverie. All rights reserved.</p>
      </footer>
    </div>
  );
}

const styles = {
  container: {
    minHeight: '100vh',
    backgroundColor: '#000',
    color: '#fff',
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
  },
  header: {
    maxWidth: '800px',
    margin: '0 auto',
    padding: '40px 20px 20px',
    borderBottom: '1px solid #222',
  },
  backLink: {
    color: '#888',
    textDecoration: 'none' as const,
    fontSize: '16px',
    marginBottom: '20px',
    display: 'inline-block',
  },
  title: {
    fontSize: '36px',
    fontWeight: 'bold' as const,
    marginBottom: '20px',
    color: '#fff',
  },
  main: {
    maxWidth: '800px',
    margin: '0 auto',
    padding: '40px 20px',
  },
  content: {
    lineHeight: '1.6',
  },
  section: {
    marginBottom: '50px',
  },
  sectionTitle: {
    fontSize: '24px',
    fontWeight: 'bold' as const,
    marginBottom: '25px',
    color: '#fff',
    paddingBottom: '10px',
    borderBottom: '2px solid #333',
  },
  faqItem: {
    marginBottom: '25px',
    backgroundColor: '#111',
    padding: '20px',
    borderRadius: '8px',
  },
  faqQuestion: {
    fontSize: '18px',
    fontWeight: '600' as const,
    marginBottom: '10px',
    color: '#fff',
  },
  faqAnswer: {
    fontSize: '16px',
    color: '#aaa',
    lineHeight: '1.5',
  },
  contactText: {
    fontSize: '16px',
    color: '#aaa',
    marginBottom: '30px',
  },
  contactMethods: {
    display: 'flex',
    gap: '30px',
    flexWrap: 'wrap' as const,
  },
  contactMethod: {
    flex: '1',
    minWidth: '250px',
    backgroundColor: '#111',
    padding: '25px',
    borderRadius: '8px',
  },
  contactTitle: {
    fontSize: '18px',
    fontWeight: '600' as const,
    marginBottom: '15px',
    color: '#fff',
  },
  contactLink: {
    color: '#4dabf7',
    textDecoration: 'none' as const,
    fontSize: '16px',
    display: 'block',
    marginBottom: '10px',
  },
  contactNote: {
    fontSize: '14px',
    color: '#666',
  },
  appInfo: {
    backgroundColor: '#111',
    padding: '25px',
    borderRadius: '8px',
  },
  footer: {
    maxWidth: '800px',
    margin: '0 auto',
    padding: '40px 20px',
    borderTop: '1px solid #222',
    textAlign: 'center' as const,
  },
  footerLinks: {
    display: 'flex',
    justifyContent: 'center',
    gap: '30px',
    marginBottom: '20px',
    flexWrap: 'wrap' as const,
  },
  footerLink: {
    color: '#888',
    textDecoration: 'none' as const,
    fontSize: '16px',
  },
  copyright: {
    color: '#666',
    fontSize: '14px',
    marginTop: '20px',
  },
};