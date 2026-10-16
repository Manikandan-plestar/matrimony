-- ========================================================
-- Matrimony Dummy Seed Data for phpMyAdmin
-- Database: matrimony_db
-- ========================================================

USE `matrimony_db`;

-- 1. Insert Dummy Users
INSERT INTO `mat_users` (`id`, `email`, `full_name`, `country_code`, `mobile_number`, `profile_photo_url`, `has_published_profile`)
VALUES
(2, 'aravind.groom@example.com', 'Aravind Swaminathan', '+91', '9876543210', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80', 1),
(3, 'rohit.groom@example.com', 'Dr. Rohit Verma', '+91', '9876543211', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80', 1),
(4, 'karthik.groom@example.com', 'Karthik Subramanian', '+91', '9876543212', 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80', 1),
(5, 'priya.bride@example.com', 'Priya Dharshini', '+91', '9876543213', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80', 1),
(6, 'ananya.bride@example.com', 'Ananya Sharma', '+91', '9876543214', 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&auto=format&fit=crop&q=80', 1),
(7, 'deepika.bride@example.com', 'Deepika Nair', '+91', '9876543215', 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&auto=format&fit=crop&q=80', 1)
ON DUPLICATE KEY UPDATE full_name = VALUES(full_name);

-- 2. Insert Dummy Profiles (Grooms and Brides)
INSERT INTO `mat_profiles` (
  `id`, `user_id`, `profile_code`, `created_for`, `full_name`, `gender`, `date_of_birth`, `age`,
  `marital_status`, `height`, `mother_tongue`, `religion`, `community`, `dietary_preference`,
  `profile_photo_url`, `country_code`, `phone`, `address`, `highest_education`, `occupation`,
  `company`, `annual_income`, `country`, `state`, `city`, `locality`,
  `family_type`, `family_background`, `family_values`,
  `pref_age_min`, `pref_age_max`, `pref_marital_status`, `pref_location`, `pref_education`, `pref_occupation`,
  `partner_expectations`, `bio`, `is_verified`, `is_premium`, `compatibility_score`, `status`
) VALUES
-- GROOM 1
(1, 2, 'MAT-G101', 'Self', 'Aravind Swaminathan', 'Groom', '1996-05-14', 29,
 'Never Married', '5 ft 11 in (180 cm)', 'Tamil', 'Hindu', 'Brahmin - Iyer', 'Vegetarian',
 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80',
 '+91', '+91 98765 43210', 'Anna Nagar, Chennai, Tamil Nadu', 'M.S. in Computer Science', 'Senior Cloud Architect',
 'Amazon Web Services', '₹28 - 35 Lakhs P.A.', 'India', 'Tamil Nadu', 'Chennai', 'Anna Nagar',
 'Nuclear Family', 'Father is a retired Bank Manager, Mother is a homemaker. Younger sister is married.', 'Moderate',
 24, 28, 'Never Married', 'Any Worldwide Location', 'Master’s or Bachelor’s in Engineering / Management', 'IT / Professional',
 'Looking for an understanding, broad-minded life partner with strong cultural values.',
 'Tech enthusiast passionate about distributed systems and classical Carnatic music. Enjoy weekend cycling and exploring traditional cuisines.',
 1, 1, 94, 'published'),

-- GROOM 2
(2, 3, 'MAT-G102', 'Parents', 'Dr. Rohit Verma', 'Groom', '1995-09-20', 30,
 'Never Married', '6 ft 0 in (183 cm)', 'Hindi', 'Hindu', 'Kayastha', 'Non-Vegetarian',
 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80',
 '+91', '+91 98765 43211', 'Indiranagar, Bangalore, Karnataka', 'M.D. Cardiology (AIIMS)', 'Cardiologist',
 'Manipal Hospital', '₹35 - 50 Lakhs P.A.', 'India', 'Karnataka', 'Bangalore', 'Indiranagar',
 'Joint Family', 'Respected family of doctors and civil servants based in Bangalore and Delhi.', 'Traditional',
 25, 29, 'Never Married', 'Any Worldwide Location', 'Medical or Healthcare Professional', 'Doctor / Professional',
 'Seeking an educated, kind-hearted companion who respects professional commitments and family togetherness.',
 'Dedicated cardiologist by day, avid reader and badminton player by dusk. Looking forward to building a meaningful life grounded in mutual respect.',
 1, 1, 91, 'published'),

-- GROOM 3
(3, 4, 'MAT-G103', 'Self', 'Karthik Subramanian', 'Groom', '1997-11-08', 28,
 'Never Married', '5 ft 9 in (175 cm)', 'Tamil', 'Hindu', 'Mudaliar', 'Eggetarian',
 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80',
 '+91', '+91 98765 43212', 'Velachery, Chennai, Tamil Nadu', 'B.Tech + MBA (IIM Lucknow)', 'Product Manager',
 'Google India', '₹40 - 55 Lakhs P.A.', 'India', 'Tamil Nadu', 'Chennai', 'Velachery',
 'Nuclear Family', 'Upper middle-class family. Father runs a logistics business, Mother is a school principal.', 'Liberal',
 24, 27, 'Never Married', 'Any Worldwide Location', 'B.Tech / MBA / Masters', 'Corporate / Tech / Creative',
 'Looking for someone who is career-driven, humorous, and values open communication.',
 'Love building intuitive software products, traveling to offbeat mountains, and photography.',
 1, 0, 88, 'published'),

-- BRIDE 1
(4, 5, 'MAT-B201', 'Self', 'Priya Dharshini', 'Bride', '1998-07-22', 27,
 'Never Married', '5 ft 6 in (168 cm)', 'Tamil', 'Hindu', 'Brahmin - Iyengar', 'Vegetarian',
 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80',
 '+91', '+91 98765 43213', 'T. Nagar, Chennai, Tamil Nadu', 'M.Tech in Data Science (IIT Madras)', 'AI Research Scientist',
 'Microsoft Research', '₹30 - 40 Lakhs P.A.', 'India', 'Tamil Nadu', 'Chennai', 'T. Nagar',
 'Nuclear Family', 'Father is a retired Professor, Mother is a Chartered Accountant.', 'Moderate',
 27, 31, 'Never Married', 'Any Worldwide Location', 'Master’s or Engineering / Tech', 'IT / Software / Science',
 'Seeking a forward-thinking, caring partner with intellectual curiosity and mutual respect.',
 'Passionate about deep learning, Bharatanatyam dance, and watercolor painting. Value honesty and simple joy in life.',
 1, 1, 96, 'published'),

-- BRIDE 2
(5, 6, 'MAT-B202', 'Self', 'Ananya Sharma', 'Bride', '1999-03-12', 26,
 'Never Married', '5 ft 5 in (165 cm)', 'Hindi', 'Hindu', 'Brahmin', 'Vegetarian',
 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&auto=format&fit=crop&q=80',
 '+91', '+91 98765 43214', 'Bandra West, Mumbai, Maharashtra', 'MBA in Marketing (XLRI)', 'Brand Strategy Director',
 'Unilever', '₹25 - 35 Lakhs P.A.', 'India', 'Maharashtra', 'Mumbai', 'Bandra',
 'Nuclear Family', 'Well-settled Mumbai family with modern outlook and deep rooted Indian values.', 'Liberal',
 26, 30, 'Never Married', 'Any Worldwide Location', 'Post Graduate / Masters', 'Corporate / Professional',
 'Looking for a supportive, cheerful life partner who believes in egalitarian marriage and partnership.',
 'Storyteller at heart, coffee aficionado, and weekend marathon runner. I believe empathy and laughter are the foundation of love.',
 1, 1, 92, 'published'),

-- BRIDE 3
(6, 7, 'MAT-B203', 'Parents', 'Deepika Nair', 'Bride', '1997-12-05', 28,
 'Never Married', '5 ft 7 in (170 cm)', 'Malayalam', 'Hindu', 'Nair', 'Non-Vegetarian',
 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&auto=format&fit=crop&q=80',
 '+91', '+91 98765 43215', 'Panampilly Nagar, Kochi, Kerala', 'Chartered Accountant (CA)', 'Finance VP',
 'Deloitte Advisory', '₹32 - 42 Lakhs P.A.', 'India', 'Kerala', 'Kochi', 'Panampilly Nagar',
 'Nuclear Family', 'Father is a retired Naval Commander, Mother is an entrepreneur.', 'Moderate',
 27, 32, 'Never Married', 'Any Worldwide Location', 'CA / MBA / Engineering', 'Finance / Tech / Corporate',
 'Seeking a mature, compassionate gentleman with good family values and passion for life.',
 'CA by profession, classical pianist and scuba diver by passion. Looking forward to finding my best friend and life partner.',
 1, 0, 89, 'published')
ON DUPLICATE KEY UPDATE full_name = VALUES(full_name), status = 'published';

-- 3. Link Users to their active profiles
UPDATE `mat_users` SET `active_profile_id` = 1 WHERE `id` = 2;
UPDATE `mat_users` SET `active_profile_id` = 2 WHERE `id` = 3;
UPDATE `mat_users` SET `active_profile_id` = 3 WHERE `id` = 4;
UPDATE `mat_users` SET `active_profile_id` = 4 WHERE `id` = 5;
UPDATE `mat_users` SET `active_profile_id` = 5 WHERE `id` = 6;
UPDATE `mat_users` SET `active_profile_id` = 6 WHERE `id` = 7;
