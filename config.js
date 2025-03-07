module.exports = {
  autodiscover: true,
  endpoint: '{{.Endpoint}}',
  onboardingConfig: {
    extends: ['config:recommended', ':disableDependencyDashboard', 'group:allNonMajor'],
  },
  onboardingConfigFileName: '.github/renovate.json',
  platform: 'github',
  token: '{{.InstallationToken}}',
}
