import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';

class ProfileDashboardScreen extends StatelessWidget {
  const ProfileDashboardScreen({
    super.key,
    required this.userId,
    required this.accountRole,
  });

  final String userId;
  final String accountRole;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final user = FirebaseAuth.instance.currentUser;
        final storedName = data['fullName'] as String?;
        final displayName = user?.displayName;
        final name = storedName?.trim().isNotEmpty == true
            ? storedName!.trim()
            : displayName?.trim().isNotEmpty == true
            ? displayName!.trim()
            : user?.email?.split('@').first ?? 'Dorm Explorer';
        final email = (data['email'] as String?) ?? user?.email ?? '—';
        final storedPhone = data['phone'] as String?;
        final phone = storedPhone?.trim().isNotEmpty == true
            ? storedPhone!.trim()
            : 'Not provided';
        final role = (data['role'] as String?) ?? accountRole;
        final isLandlord = role == 'landlord';
        final verified = user?.emailVerified ?? false;
        final roleLabel = isLandlord
            ? 'Landlord (Verified Host)'
            : 'Seeker (Student Account)';
        final tier = isLandlord
            ? 'Landlord (Verified Host)'
            : 'Seeker (Student / Professional)';
        final explanation = isLandlord
            ? 'As a Landlord, you can manage your dormitory listings and connect with students looking for accommodation in Batangas City.'
            : 'As a Seeker, you can browse accommodations, save dorms, and contact landlords through DormTheExplorer.';

        return Column(
          children: [
            const _ProfileHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth > 1032
                      ? 1000.0
                      : constraints.maxWidth;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: width),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: _ProfileIdentityCard(
                                name: name,
                                roleLabel: roleLabel,
                                location: 'Batangas City',
                                photoUrl: user?.photoURL,
                                userId: userId,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'ACCOUNT CREDENTIALS',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color:
                                                    AppTheme.onSurfaceVariant,
                                                letterSpacing: 1,
                                              ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 14,
                                        color: AppTheme.secondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Firebase Authenticated',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppTheme.secondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.onSurface.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        _ProfileField(
                                          icon: Icons.person_outline_rounded,
                                          label: 'Full Legal Name',
                                          value: name,
                                        ),
                                        const _ProfileDivider(),
                                        _ProfileField(
                                          icon: Icons.mail_outline_rounded,
                                          label:
                                              'Institutional / Primary Email',
                                          value: email,
                                          verified: verified,
                                        ),
                                        const _ProfileDivider(),
                                        _ProfileField(
                                          icon: Icons.phone_outlined,
                                          label: 'Mobile Contact',
                                          value: phone,
                                        ),
                                        const _ProfileDivider(),
                                        _ProfileField(
                                          icon: Icons.verified_user_outlined,
                                          label: 'Access Tier',
                                          value: tier,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 20,
                                      color: AppTheme.primaryDeep,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        explanation,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                              child: SizedBox(
                                height: 48,
                                child: FilledButton.icon(
                                  onPressed: () => _signOut(context),
                                  icon: const Icon(Icons.logout_rounded),
                                  label: const Text('Log Out Securely'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.errorContainer
                                        .withValues(alpha: 0.55),
                                    foregroundColor: AppTheme.onErrorContainer,
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.shield_outlined,
                                        size: 14,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Secured via Firebase Identity Platform',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppTheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'DormTheExplorer v1.0.0 • Batangas City',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.onSurfaceVariant
                                              .withValues(alpha: 0.8),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Are you sure you want to log out of DormTheExplorer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldSignOut == true) await FirebaseAuth.instance.signOut();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              size: 20,
              color: AppTheme.onPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DormTheExplorer',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: AppTheme.primaryDeep, letterSpacing: 1),
              ),
              Text('Profile', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ProfilePicture extends StatefulWidget {
  const _ProfilePicture({
    required this.initials,
    required this.photoUrl,
    required this.userId,
  });

  final String initials;
  final String? photoUrl;
  final String userId;

  @override
  State<_ProfilePicture> createState() => _ProfilePictureState();
}

class _ProfilePictureState extends State<_ProfilePicture> {
  final ImagePicker _imagePicker = ImagePicker();
  String? _photoUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.photoUrl;
  }

  @override
  void didUpdateWidget(covariant _ProfilePicture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) {
      _photoUrl = widget.photoUrl;
    }
  }

  Future<void> _uploadPhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (image == null || !mounted) return;

      setState(() => _isUploading = true);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != widget.userId) {
        throw StateError('Your session expired. Please sign in again.');
      }

      final photoRef = FirebaseStorage.instance.ref().child(
        'profile-photos/${widget.userId}/avatar',
      );
      await photoRef.putData(await image.readAsBytes());
      final downloadUrl = await photoRef.getDownloadURL();
      await currentUser.updatePhotoURL(downloadUrl);

      if (!mounted) return;
      setState(() => _photoUrl = downloadUrl);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
    } catch (error) {
      if (!mounted) return;
      final message = error is FirebaseException
          ? error.message ?? 'Could not upload your profile photo.'
          : 'Could not upload your profile photo. Please try again.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted && _isUploading) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 88,
          height: 96,
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 4,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: _photoUrl == null
                      ? _initials(context)
                      : Image.network(
                          _photoUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _initials(context),
                        ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.surfaceContainerLowest,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    size: 14,
                    color: AppTheme.onSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: _isUploading ? null : _uploadPhoto,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 28),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          icon: _isUploading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_a_photo_outlined, size: 15),
          label: Text(_isUploading ? 'Uploading…' : 'Upload photo'),
        ),
      ],
    );
  }

  Widget _initials(BuildContext context) => Text(
    widget.initials,
    style: Theme.of(context).textTheme.headlineLarge
        ?.copyWith(color: AppTheme.primaryDeep, fontWeight: FontWeight.w700),
  );
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({
    required this.name,
    required this.roleLabel,
    required this.location,
    required this.photoUrl,
    required this.userId,
  });

  final String name;
  final String roleLabel;
  final String location;
  final String? photoUrl;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _ProfilePicture(
            initials: initials,
            photoUrl: photoUrl,
            userId: userId,
          ),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(letterSpacing: -0.3),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.secondaryFixed.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              roleLabel,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppTheme.onSecondaryFixedVariant),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppTheme.primaryDeep,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  location,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
    this.verified = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryDeep),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryFixed.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Verified',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTheme.onSecondaryFixedVariant,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Divider(height: 1, color: AppTheme.surfaceContainer),
  );
}
