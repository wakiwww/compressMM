import React from 'react';

export default function Terms() {
  return (
    <div style={styles.container}>
      <header style={styles.header}>
        <nav style={styles.nav}>
          <a href="/" style={styles.navLink}>← 返回首页</a>
        </nav>
        <h1 style={styles.title}>使用条款</h1>
        <p style={styles.date}>最后更新日期: 2024年8月11日</p>
      </header>

      <main style={styles.main}>
        <section style={styles.section}>
          <p style={styles.intro}>
            欢迎使用 werck it!- video degrader（压烂它！）。请仔细阅读以下使用条款。使用本应用即表示您同意遵守这些条款。
          </p>
        </section>

        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>1. 应用许可</h2>
          <p style={styles.text}>
            在您遵守本条款的前提下，我们授予您个人、非独占的许可，以在您的设备上使用本应用。
          </p>
        </section>

        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>2. 使用限制</h2>
          <div style={styles.list}>
            <p>您同意不：</p>
            <ul>
              <li>对本应用进行反向工程或反编译</li>
              <li>使用本应用进行任何非法活动</li>
              <li>侵犯他人的知识产权</li>
              <li>传播恶意软件或病毒</li>
            </ul>
          </div>
        </section>

        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>3. 用户内容</h2>
          <p style={styles.text}>
            您对本应用中处理的视频内容全权负责。您声明并保证您拥有或有权使用所有处理的内容。
          </p>
        </section>

        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>4. 免责声明</h2>
          <p style={styles.text}>
            本应用按"原样"提供，不附带任何明示或暗示的保证。我们不保证本应用将满足您的要求或无中断。
          </p>
        </section>

        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>5. 责任限制</h2>
          <p style={styles.text}>
            在法律允许的最大范围内，我们对您因使用本应用而产生的任何索赔的总责任不超过您为使用本应用支付的金额。
          </p>
        </section>

        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>6. 条款变更</h2>
          <p style={styles.text}>
            我们保留随时修改这些条款的权利。更新后的条款将在本页面发布，您继续使用本应用即表示您接受更新后的条款。
          </p>
        </section>

        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>7. 联系我们</h2>
          <div style={styles.contact}>
            <p><strong>法律相关：</strong> legal@werckit-app.com</p>
            <p><strong>技术支持：</strong> <a href="/support" style={styles.link}>werckit-app.com/support</a></p>
          </div>
        </section>

        <section style={styles.note}>
          <p>
            <strong>重要提示：</strong>在使用 werck it!- video degrader（压烂它！）应用前，请确保您已阅读、理解并同意这些使用条款。
            如果您不同意这些条款，请不要使用本应用。
          </p>
        </section>
      </main>

      <footer style={styles.footer}>
        <div style={styles.footerLinks}>
          <a href="/" style={styles.footerLink}>首页</a>
          <a href="/support" style={styles.footerLink}>技术支持</a>
          <a href="/privacy" style={styles.footerLink}>隐私政策</a>
        </div>
        <p>© 2024 werck it!- video degrader（压烂它！）. All rights reserved.</p>
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
    lineHeight: '1.6',
  },
  header: {
    marginBottom: '40px',
    borderBottom: '1px solid #333',
    paddingBottom: '20px',
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
    marginBottom: '10px',
    color: '#fff',
  },
  date: {
    color: '#666',
    fontSize: '14px',
  },
  main: {
    marginBottom: '40px',
  },
  section: {
    marginBottom: '30px',
    padding: '20px',
    backgroundColor: '#111',
    borderRadius: '8px',
  },
  intro: {
    fontSize: '18px',
    color: '#aaa',
    marginBottom: '20px',
  },
  sectionTitle: {
    fontSize: '24px',
    fontWeight: '600' as const,
    marginBottom: '15px',
    color: '#fff',
    borderBottom: '2px solid #333',
    paddingBottom: '10px',
  },
  text: {
    fontSize: '16px',
    color: '#aaa',
    marginBottom: '15px',
  },
  list: {
    backgroundColor: '#1a1a1a',
    padding: '20px',
    borderRadius: '8px',
    marginTop: '10px',
  },
  contact: {
    backgroundColor: '#1a1a1a',
    padding: '20px',
    borderRadius: '8px',
    marginTop: '20px',
  },
  link: {
    color: '#4dabf7',
    textDecoration: 'none' as const,
  },
  note: {
    backgroundColor: '#1a1a1a',
    padding: '25px',
    borderRadius: '8px',
    borderLeft: '4px solid #4dabf7',
    marginTop: '30px',
  },
  footer: {
    textAlign: 'center' as const,
    paddingTop: '20px',
    borderTop: '1px solid #333',
    color: '#666',
  },
  footerLinks: {
    display: 'flex',
    justifyContent: 'center',
    gap: '20px',
    marginBottom: '20px',
    flexWrap: 'wrap' as const,
  },
  footerLink: {
    color: '#888',
    textDecoration: 'none' as const,
    fontSize: '16px',
  },
};