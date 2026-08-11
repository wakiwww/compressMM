import React from 'react';

export default function Support() {
  return (
    <div style={styles.container}>
      <header style={styles.header}>
        <nav style={styles.nav}>
          <a href="/" style={styles.navLink}>← 返回首页</a>
        </nav>
        <h1 style={styles.title}>技术支持</h1>
      </header>

      <main style={styles.main}>
        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>常见问题</h2>

          <div style={styles.faq}>
            <h3 style={styles.faqQuestion}>如何联系技术支持？</h3>
            <p style={styles.faqAnswer}>请发送邮件至 support@reverie-app.com，我们会在24小时内回复。</p>
          </div>

          <div style={styles.faq}>
            <h3 style={styles.faqQuestion}>应用遇到问题怎么办？</h3>
            <p style={styles.faqAnswer}>请尝试重启应用，如果问题依旧，请联系我们并提供详细的错误描述。</p>
          </div>

          <div style={styles.faq}>
            <h3 style={styles.faqQuestion}>在哪里可以查看隐私政策？</h3>
            <p style={styles.faqAnswer}>请访问 <a href="/privacy" style={styles.link}>隐私政策页面</a>。</p>
          </div>
        </section>

        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>联系我们</h2>
          <div style={styles.contact}>
            <p><strong>电子邮件：</strong> support@reverie-app.com</p>
            <p><strong>响应时间：</strong> 24-48小时</p>
            <p><strong>服务时间：</strong> 周一至周五 9:00-18:00</p>
          </div>
        </section>
      </main>

      <footer style={styles.footer}>
        <p>© 2024 Rêverie. 技术支持中心</p>
      </footer>
    </div>
  );
}

const styles = {
  container: {
    minHeight: '100vh',
    backgroundColor: '#000',
    color: '#fff',
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
    padding: '20px',
    maxWidth: '800px',
    margin: '0 auto',
  },
  header: {
    marginBottom: '40px',
  },
  nav: {
    marginBottom: '20px',
  },
  navLink: {
    color: '#888',
    textDecoration: 'none' as const,
    fontSize: '16px',
  },
  title: {
    fontSize: '36px',
    fontWeight: 'bold' as const,
    marginBottom: '20px',
    color: '#fff',
  },
  main: {
    lineHeight: '1.6',
  },
  section: {
    marginBottom: '40px',
    padding: '20px',
    backgroundColor: '#111',
    borderRadius: '8px',
  },
  sectionTitle: {
    fontSize: '24px',
    fontWeight: '600' as const,
    marginBottom: '20px',
    color: '#fff',
    borderBottom: '2px solid #333',
    paddingBottom: '10px',
  },
  faq: {
    marginBottom: '25px',
    padding: '15px',
    backgroundColor: '#1a1a1a',
    borderRadius: '6px',
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
  },
  contact: {
    backgroundColor: '#1a1a1a',
    padding: '20px',
    borderRadius: '8px',
  },
  link: {
    color: '#4dabf7',
    textDecoration: 'none' as const,
  },
  footer: {
    textAlign: 'center' as const,
    marginTop: '50px',
    paddingTop: '20px',
    borderTop: '1px solid #333',
    color: '#666',
  },
};