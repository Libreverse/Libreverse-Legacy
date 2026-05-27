# Service for adding example experiences to Libreverse
# Based on the rails runner script for creating sample experiences
class ExampleExperiencesService
  class << self
    def add_examples
      Rails.logger.debug "🎯 Adding example experiences to Libreverse..."

      demo_owner = find_or_create_demo_owner_account

      created_count = 0
      failed_count = 0

      index = 0
      while index < sample_html_files.length
        html_file_data = sample_html_files[index]
        exp_data = experiences_data[index]
        Rails.logger.debug "\n📝 Creating: '#{exp_data[:title]}'..."

        begin
          # Skip if experience already exists
          if Experience.exists?(title: exp_data[:title], author: exp_data[:author])
            Rails.logger.debug "   ⚠️  Experience '#{exp_data[:title]}' already exists, skipping..."
            next
          end

          experience = create_experience_with_file(exp_data, html_file_data, demo_owner)

          if experience.persisted?
            Rails.logger.debug "   ✅ Successfully created '#{experience.title}' (ID: #{experience.id})"
            created_count += 1
          else
            Rails.logger.debug "   ❌ Failed to create '#{exp_data[:title]}': #{experience.errors.full_messages.join(', ')}"
            failed_count += 1
          end

          # Small delay between creations
          sleep(0.1)
        rescue StandardError => e
          Rails.logger.debug "   ❌ Error creating '#{exp_data[:title]}': #{e.message}"
          failed_count += 1
        end

        index += 1
      end

      print_summary(created_count, failed_count)

      { created: created_count, failed: failed_count }
    end

    def delete_examples
      example_titles = experiences_data.map { |exp| exp[:title] }
      deleted_count = Experience.where(title: example_titles).destroy_all.count
      { deleted: deleted_count }
    end

    def experience_data
      [
        {
          title: "Virtual Art Gallery Experience",
          description: "Step into a beautiful virtual art gallery featuring digital artworks and interactive displays. Explore different artistic styles and immerse yourself in a curated collection of digital masterpieces.",
          author: "Gallery Curator",
          html_file_data: {
            filename: "virtual_gallery.html",
            content: virtual_gallery_html
          }
        },
        {
          title: "Interactive Fantasy Adventure",
          description: "Embark on a choose-your-own-adventure story set in a mysterious enchanted forest. Make decisions that shape your journey and discover the secrets hidden within the mystical woodland.",
          author: "Story Weaver",
          html_file_data: {
            filename: "fantasy_adventure.html",
            content: fantasy_adventure_html
          }
        },
        {
          title: "Space Mission Control Dashboard",
          description: "Experience life as a space mission controller with this interactive dashboard. Monitor multiple planets, track space missions, and stay connected with deep space communications.",
          author: "Astronaut Alpha",
          html_file_data: {
            filename: "space_dashboard.html",
            content: space_dashboard_html
          }
        },
        {
          title: "Dynamic Audio Visualizer",
          description: "A mesmerizing audio visualization experience with multiple modes and interactive controls. Watch as sound comes to life through beautiful animated graphics and responsive visual effects.",
          author: "Sound Engineer",
          html_file_data: {
            filename: "music_visualizer.html",
            content: music_visualizer_html
          }
        },
        {
          title: "Interactive Digital Garden",
          description: "Create and tend your own digital garden! Plant flowers, add clouds, make it rain, and watch your virtual garden grow. A peaceful and interactive nature experience.",
          author: "Digital Gardener",
          html_file_data: {
            filename: "digital_garden.html",
            content: digital_garden_html
          }
        },
        {
          title: "Retro Arcade Experience",
          description: "A nostalgic journey back to the golden age of arcade games. Features classic game aesthetics, pixel art styling, and interactive elements that capture the spirit of retro gaming.",
          author: "Pixel Artist",
          html_file_data: {
            filename: "retro_arcade.html",
            content: retro_arcade_html
          }
        }
      ]
    end

    private

    def find_or_create_demo_owner_account
      account = SystemAccounts.find_or_create_demo_experiences_owner!
      Rails.logger.debug "✅ Using demo experiences owner: #{account.username} (ID: #{account.id})"
      account
    end

    def create_experience_with_file(exp_data, html_file_data, owner_account)
      # Create the experience
      experience = Experience.new(
        title: exp_data[:title],
        description: exp_data[:description],
        author: exp_data[:author],
        account: owner_account,
        approved: true, # Auto-approve demo content owned by the system demo account
        offline_available: exp_data.fetch(:offline_available) { true } # Default to true for examples
      )

      # Create and attach the HTML file
      html_content = html_file_data[:content]
      filename = html_file_data[:filename]

      # Create a StringIO object to avoid writing decrypted data to disk
      html_io = StringIO.new(html_content)

      # Attach the file
      experience.html_file.attach(
        io: html_io,
        filename: filename,
        content_type: "text/html"
      )

      # Save the experience (skip validations to bypass moderation for demo data)
      experience.save!(validate: false)

      temp_file.close
      temp_file.unlink

      experience
    end

    def print_summary(created_count, failed_count)
      Rails.logger.debug "\n#{'=' * 60}"
      Rails.logger.debug "🎯 Experience Creation Summary:"
      Rails.logger.debug "   ✅ Successfully created: #{created_count} experiences"
      Rails.logger.debug "   ❌ Failed to create: #{failed_count} experiences"
      Rails.logger.debug "   📊 Total experiences in database: #{Experience.count}"
      Rails.logger.debug "   🎉 Approved experiences: #{Experience.approved.count}"
      Rails.logger.debug "   ⏳ Pending approval: #{Experience.pending_approval.count}"

      if created_count.positive?
        Rails.logger.debug "\n🚀 Great! You now have example experiences to explore."
        Rails.logger.debug "   💡 Visit the experiences page to see them in action!"
        Rails.logger.debug "   🔗 Or use the API to interact with them programmatically."
      end

      Rails.logger.debug "\n🎉 Done! Your Libreverse instance now has sample content to explore."
    end

    def sample_html_files
      [
        {
          filename: "virtual_gallery.html",
          content: virtual_gallery_html
        },
        {
          filename: "interactive_story.html",
          content: interactive_story_html
        },
        {
          filename: "space_exploration.html",
          content: space_exploration_html
        },
        {
          filename: "music_visualizer.html",
          content: music_visualizer_html
        },
        {
          filename: "digital_garden.html",
          content: digital_garden_html
        },
        {
          filename: "retro_arcade.html",
          content: retro_arcade_html
        },
        {
          filename: "meditation_space.html",
          content: meditation_space_html
        }
      ]
    end

    def experiences_data
      [
        {
          title: "Virtual Art Gallery Experience",
          description: "Step into a beautiful virtual art gallery featuring digital artworks and interactive displays. Explore different artistic styles and immerse yourself in a curated collection of digital masterpieces.",
          author: "Gallery Curator",
          offline_available: true
        },
        {
          title: "Interactive Fantasy Adventure",
          description: "Embark on a choose-your-own-adventure story set in a mysterious enchanted forest. Make decisions that shape your journey and discover the secrets hidden within the mystical woodland.",
          author: "Story Weaver",
          offline_available: true
        },
        {
          title: "Space Mission Control Dashboard",
          description: "Experience life as a space mission controller with this interactive dashboard. Monitor multiple planets, track space missions, and stay connected with deep space communications.",
          author: "Astronaut Alpha",
          offline_available: true
        },
        {
          title: "Dynamic Audio Visualizer",
          description: "A mesmerizing audio visualization experience with multiple modes and interactive controls. Watch as sound comes to life through beautiful animated graphics and responsive visual effects.",
          author: "Sound Engineer",
          offline_available: true
        },
        {
          title: "Interactive Digital Garden",
          description: "Create and tend your own digital garden! Plant flowers, add clouds, make it rain, and watch your virtual garden grow. A peaceful and interactive nature experience.",
          author: "Digital Gardener",
          offline_available: true
        },
        {
          title: "Retro Arcade Experience",
          description: "A nostalgic journey back to the golden age of arcade games. Features classic game aesthetics, pixel art styling, and interactive elements that capture the spirit of retro gaming.",
          author: "Pixel Artist",
          offline_available: true
        },
        {
          title: "Meditation and Mindfulness Space",
          description: "A tranquil digital environment designed for meditation and relaxation. Features ambient sounds, breathing exercises, and calming visual elements to help you find inner peace.",
          author: "Zen Master",
          offline_available: true
        }
      ]
    end

    def virtual_gallery_html
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Virtual Art Gallery</title>
            <style>
                body { margin: 0; font-family: Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
                .gallery { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; padding: 20px; }
                .artwork { background: white; border-radius: 10px; padding: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); transition: transform 0.3s ease; }
                .artwork:hover { transform: translateY(-5px); }
                .artwork-image { width: 100%; height: 200px; background: #f0f0f0; border-radius: 5px; margin-bottom: 10px; display: flex; align-items: center; justify-content: center; }
                h1 { text-align: center; color: white; margin: 20px 0; }
            </style>
        </head>
        <body>
            <h1>🎨 Virtual Art Gallery</h1>
            <div class="gallery">
                <div class="artwork">
                    <div class="artwork-image">🖼️ Digital Landscape</div>
                    <h3>Mountain Serenity</h3>
                    <p>A peaceful digital landscape showcasing mountain ranges at sunset.</p>
                </div>
                <div class="artwork">
                    <div class="artwork-image">� City Lights</div>
                    <h3>Urban Dreams</h3>
                    <p>An abstract representation of city life through vibrant colors.</p>
                </div>
                <div class="artwork">
                    <div class="artwork-image">🌊 Ocean Waves</div>
                    <h3>Eternal Tide</h3>
                    <p>Capturing the eternal motion of ocean waves in digital art.</p>
                </div>
            </div>
        </body>
        </html>
      HTML
    end

    def interactive_story_html
      <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Interactive Adventure</title>
                <style>
                    body { margin: 0; padding: 20px; font-family: 'Georgia', serif; background: #1a1a1a; color: #f0f0f0; line-height: 1.6; }
                    .story-container { max-width: 800px; margin: 0 auto; background: #2a2a2a; padding: 30px; border-radius: 15px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
                    .choices { margin: 20px 0; }
                    .choice-btn { display: block; width: 100%; padding: 15px; margin: 10px 0; background: #4a4a4a; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; transition: background 0.3s; }
                    .choice-btn:hover { background: #5a5a5a; }
                    h1 { color: #ffd700; text-align: center; margin-bottom: 30px; }
                    .story-text { font-size: 18px; margin-bottom: 20px; }
                </style>
            </head>
            <body>
                <div class="story-container">
                    <h1>🗡️ The Mystic Forest</h1>
                    <div class="story-text" id="story">
                        You stand at the edge of a mysterious forest. Ancient trees tower above you, their branches creating intricate patterns against the starlit sky. A gentle breeze carries whispers of forgotten legends.
                    </div>
                    <div class="choices">
                        <button class="choice-btn" onclick="updateStory('path')">Take the winding path deeper into the forest</button>
                        <button class="choice-btn" onclick="updateStory('clearing')">Head towards a moonlit clearing</button>
                        <button class="choice-btn" onclick="updateStory('stream')">Follow the sound of a babbling stream</button>
                    </div>
                </div>
        #{' ' * 8}
                <script>
                    function updateStory(choice) {
                        const storyElement = document.getElementById('story');
                        switch(choice) {
                            case 'path':
                                storyElement.innerHTML = "The path winds deeper into the forest. Glowing mushrooms light your way as you discover an ancient stone circle covered in mystical runes. Magic fills the air around you.";
                                break;
                            case 'clearing':
                                storyElement.innerHTML = "In the moonlit clearing, you find a crystal-clear pond reflecting the stars above. A wise old owl perches nearby, watching you with knowing eyes.";
                                break;
                            case 'stream':
                                storyElement.innerHTML = "Following the stream, you discover it flows from an enchanted spring. The water sparkles with an otherworldly light, and you feel a sense of peace wash over you.";
                                break;
                        }
                    }
                </script>
            </body>
            </html>
      HTML
    end

    def space_exploration_html
      <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Space Exploration Dashboard</title>
                <style>
                    body { margin: 0; padding: 0; background: radial-gradient(ellipse at center, #0c1445 0%, #000000 70%); color: white; font-family: 'Courier New', monospace; height: 100vh; overflow: hidden; }
                    .dashboard { display: grid; grid-template-columns: 1fr 1fr; grid-template-rows: 1fr 1fr; height: 100vh; gap: 20px; padding: 20px; box-sizing: border-box; }
                    .panel { background: rgba(0, 50, 100, 0.3); border: 2px solid #00ffff; border-radius: 10px; padding: 20px; position: relative; }
                    .panel h2 { color: #00ffff; margin-top: 0; text-align: center; }
                    .stars { position: fixed; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; z-index: -1; }
                    .star { position: absolute; background: white; border-radius: 50%; animation: twinkle 2s infinite; }
                    @keyframes twinkle { 0%, 100% { opacity: 0.3; } 50% { opacity: 1; } }
                    .planet { width: 60px; height: 60px; border-radius: 50%; margin: 10px auto; }
                    .earth { background: linear-gradient(45deg, #4a90e2, #50c878); }
                    .mars { background: linear-gradient(45deg, #cd5c5c, #a0522d); }
                    .jupiter { background: linear-gradient(45deg, #daa520, #ff8c00); }
                    .data-stream { font-family: monospace; color: #00ff00; font-size: 12px; }
                </style>
            </head>
            <body>
                <div class="stars" id="stars"></div>
                <div class="dashboard">
                    <div class="panel">
                        <h2>🌍 Earth Status</h2>
                        <div class="planet earth"></div>
                        <div class="data-stream">
                            Orbital Velocity: 29.78 km/s<br>
                            Distance from Sun: 149.6M km<br>
                            Atmosphere: 78% N₂, 21% O₂<br>
                            Status: Habitable ✅
                        </div>
                    </div>
                    <div class="panel">
                        <h2>� Mars Mission</h2>
                        <div class="planet mars"></div>
                        <div class="data-stream">
                            Mission Status: En Route<br>
                            Travel Time: 7 months<br>
                            Crew: 6 astronauts<br>
                            Objective: Sample Collection 🚀
                        </div>
                    </div>
                    <div class="panel">
                        <h2>🪐 Jupiter Observatory</h2>
                        <div class="planet jupiter"></div>
                        <div class="data-stream">
                            Moons Detected: 79<br>
                            Great Red Spot: Active<br>
                            Magnetic Field: Intense<br>
                            Research: Ongoing 🔭
                        </div>
                    </div>
                    <div class="panel">
                        <h2>📡 Deep Space Communications</h2>
                        <div class="data-stream" id="communications">
                            [INCOMING SIGNAL]<br>
                            Source: Voyager 1<br>
                            Status: Operational<br>
                            Message: "Still exploring..."
                        </div>
                    </div>
                </div>
        #{' ' * 8}
                <script>
                    // Create twinkling stars
                    function createStars() {
                        const starsContainer = document.getElementById('stars');
                        for (let i = 0; i < 50; i++) {
                            const star = document.createElement('div');
                            star.className = 'star';
                            star.style.left = Math.random() * 100 + '%';
                            star.style.top = Math.random() * 100 + '%';
                            star.style.width = Math.random() * 3 + 1 + 'px';
                            star.style.height = star.style.width;
                            star.style.animationDelay = Math.random() * 2 + 's';
                            starsContainer.appendChild(star);
                        }
                    }
        #{' ' * 12}
                    createStars();
                </script>
            </body>
            </html>
      HTML
    end

    def music_visualizer_html
      <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Audio Visualizer</title>
                <style>
                    body { margin: 0; padding: 0; background: #000; color: white; font-family: Arial, sans-serif; height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; }
                    .visualizer { width: 800px; height: 400px; background: radial-gradient(circle, #1a1a2e 0%, #16213e 50%, #0f3460 100%); border-radius: 20px; padding: 20px; display: flex; align-items: end; justify-content: space-around; overflow: hidden; }
                    .bar { width: 8px; background: linear-gradient(to top, #ff6b6b, #4ecdc4, #45b7d1); border-radius: 4px 4px 0 0; transition: height 0.1s ease; animation: pulse 2s infinite; }
                    @keyframes pulse { 0%, 100% { opacity: 0.7; } 50% { opacity: 1; } }
                    .controls { margin-top: 20px; text-align: center; }
                    .btn { background: #4ecdc4; color: white; border: none; padding: 10px 20px; border-radius: 25px; cursor: pointer; margin: 0 10px; font-size: 16px; transition: background 0.3s; }
                    .btn:hover { background: #45b7d1; }
                    h1 { margin-bottom: 20px; background: linear-gradient(45deg, #ff6b6b, #4ecdc4); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
                </style>
            </head>
            <body>
                <h1>🎵 Audio Visualizer Experience</h1>
                <div class="visualizer" id="visualizer"></div>
                <div class="controls">
                    <button class="btn" onclick="startVisualization()">Start Visualization</button>
                    <button class="btn" onclick="changeMode()">Change Mode</button>
                    <button class="btn" onclick="randomize()">Randomize</button>
                </div>
        #{' ' * 8}
                <script>
                    let isPlaying = false;
                    let animationId;
                    let mode = 0;
        #{' ' * 12}
                    function createBars() {
                        const visualizer = document.getElementById('visualizer');
                        visualizer.innerHTML = '';
                        for (let i = 0; i < 80; i++) {
                            const bar = document.createElement('div');
                            bar.className = 'bar';
                            bar.style.height = '10px';
                            bar.style.animationDelay = (i * 0.1) + 's';
                            visualizer.appendChild(bar);
                        }
                    }
        #{' ' * 12}
                    function animateBars() {
                        const bars = document.querySelectorAll('.bar');
                        bars.forEach((bar, index) => {
                            let height;
                            switch(mode) {
                                case 0:
                                    height = Math.sin(Date.now() * 0.005 + index * 0.1) * 150 + 160;
                                    break;
                                case 1:
                                    height = Math.random() * 300 + 50;
                                    break;
                                case 2:
                                    height = Math.abs(Math.sin(Date.now() * 0.003 + index * 0.2)) * 250 + 100;
                                    break;
                            }
                            bar.style.height = height + 'px';
                        });
        #{' ' * 16}
                        if (isPlaying) {
                            animationId = requestAnimationFrame(animateBars);
                        }
                    }
        #{' ' * 12}
                    function startVisualization() {
                        isPlaying = !isPlaying;
                        if (isPlaying) {
                            animateBars();
                            event.target.textContent = 'Stop Visualization';
                        } else {
                            cancelAnimationFrame(animationId);
                            event.target.textContent = 'Start Visualization';
                        }
                    }
        #{' ' * 12}
                    function changeMode() {
                        mode = (mode + 1) % 3;
                        const modes = ['Wave', 'Random', 'Pulse'];
                        event.target.textContent = 'Mode: ' + modes[mode];
                    }
        #{' ' * 12}
                    function randomize() {
                        const bars = document.querySelectorAll('.bar');
                        bars.forEach(bar => {
                            bar.style.height = Math.random() * 300 + 50 + 'px';
                            bar.style.background = `hsl(${Math.random() * 360}, 70%, 60%)`;
                        });
                    }
        #{' ' * 12}
                    createBars();
                </script>
            </body>
            </html>
      HTML
    end

    def digital_garden_html
      <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Digital Garden</title>
                <style>
                    body { margin: 0; padding: 0; background: linear-gradient(to bottom, #87CEEB 0%, #98FB98 50%, #228B22 100%); font-family: Arial, sans-serif; height: 100vh; overflow: hidden; }
                    .garden { position: relative; width: 100%; height: 100%; }
                    .flower { position: absolute; cursor: pointer; transition: transform 0.3s ease; }
                    .flower:hover { transform: scale(1.2); }
                    .sun { position: absolute; top: 50px; right: 50px; width: 80px; height: 80px; background: radial-gradient(circle, #FFD700, #FFA500); border-radius: 50%; animation: shine 3s ease-in-out infinite; }
                    @keyframes shine { 0%, 100% { box-shadow: 0 0 20px #FFD700; } 50% { box-shadow: 0 0 40px #FFD700; } }
                    .cloud { position: absolute; background: white; border-radius: 50px; opacity: 0.8; animation: float 10s linear infinite; }
                    .cloud::before, .cloud::after { content: ''; position: absolute; background: white; border-radius: 50px; }
                    .controls { position: absolute; bottom: 20px; left: 50%; transform: translateX(-50%); text-align: center; }
                    .garden-btn { background: rgba(34, 139, 34, 0.8); color: white; border: none; padding: 10px 20px; border-radius: 20px; margin: 0 5px; cursor: pointer; }
                    .garden-btn:hover { background: rgba(34, 139, 34, 1); }
                    .counter { position: absolute; top: 20px; left: 20px; background: rgba(255, 255, 255, 0.8); padding: 10px; border-radius: 10px; }
                </style>
            </head>
            <body>
                <div class="garden" id="garden">
                    <div class="sun"></div>
                    <div class="counter">
                        <div>🌸 Flowers: <span id="flower-count">0</span></div>
                        <div>☁️ Clouds: <span id="cloud-count">3</span></div>
                    </div>
                    <div class="controls">
                        <button class="garden-btn" onclick="plantFlower()">� Plant Flower</button>
                        <button class="garden-btn" onclick="addCloud()">☁️ Add Cloud</button>
                        <button class="garden-btn" onclick="clearGarden()">🧹 Clear Garden</button>
                        <button class="garden-btn" onclick="makeItRain()">🌧️ Rain</button>
                    </div>
                </div>
        #{' ' * 8}
                <script>
                    let flowerCount = 0;
                    let cloudCount = 3;
        #{' ' * 12}
                    const flowers = ['🌸', '🌺', '🌻', '🌷', '🌹', '💐', '🌼'];
        #{' ' * 12}
                    function plantFlower() {
                        const garden = document.getElementById('garden');
                        const flower = document.createElement('div');
                        flower.className = 'flower';
                        flower.innerHTML = flowers[Math.floor(Math.random() * flowers.length)];
                        flower.style.fontSize = (Math.random() * 30 + 20) + 'px';
                        flower.style.left = Math.random() * (window.innerWidth - 50) + 'px';
                        flower.style.top = Math.random() * (window.innerHeight - 200) + 100 + 'px';
                        flower.onclick = function() { this.remove(); updateFlowerCount(-1); };
                        garden.appendChild(flower);
                        updateFlowerCount(1);
        #{' ' * 16}
                        // Grow animation
                        flower.style.transform = 'scale(0)';
                        setTimeout(() => { flower.style.transform = 'scale(1)'; }, 10);
                    }
        #{' ' * 12}
                    function addCloud() {
                        const garden = document.getElementById('garden');
                        const cloud = document.createElement('div');
                        cloud.className = 'cloud';
                        cloud.style.width = (Math.random() * 60 + 40) + 'px';
                        cloud.style.height = (Math.random() * 30 + 20) + 'px';
                        cloud.style.top = Math.random() * 200 + 50 + 'px';
                        cloud.style.left = '-100px';
                        cloud.style.animationDuration = (Math.random() * 10 + 15) + 's';
                        garden.appendChild(cloud);
        #{' ' * 16}
                        setTimeout(() => cloud.remove(), 25000);
                        updateCloudCount(1);
                    }
        #{' ' * 12}
                    function clearGarden() {
                        const flowers = document.querySelectorAll('.flower');
                        flowers.forEach(flower => flower.remove());
                        flowerCount = 0;
                        document.getElementById('flower-count').textContent = flowerCount;
                    }
        #{' ' * 12}
                    function makeItRain() {
                        const garden = document.getElementById('garden');
                        for (let i = 0; i < 20; i++) {
                            setTimeout(() => {
                                const raindrop = document.createElement('div');
                                raindrop.innerHTML = '💧';
                                raindrop.style.position = 'absolute';
                                raindrop.style.left = Math.random() * window.innerWidth + 'px';
                                raindrop.style.top = '-20px';
                                raindrop.style.fontSize = '20px';
                                raindrop.style.animation = 'fall 2s linear';
                                raindrop.style.pointerEvents = 'none';
                                garden.appendChild(raindrop);
        #{' ' * 24}
                                setTimeout(() => raindrop.remove(), 2000);
                            }, i * 100);
                        }
                    }
        #{' ' * 12}
                    function updateFlowerCount(delta) {
                        flowerCount += delta;
                        document.getElementById('flower-count').textContent = flowerCount;
                    }
        #{' ' * 12}
                    function updateCloudCount(delta) {
                        cloudCount += delta;
                        document.getElementById('cloud-count').textContent = cloudCount;
                    }
        #{' ' * 12}
                    // Initialize with some clouds
                    for (let i = 0; i < 3; i++) {
                        setTimeout(addCloud, i * 2000);
                    }
        #{' ' * 12}
                    // Add CSS for falling animation
                    const style = document.createElement('style');
                    style.textContent = `
                        @keyframes fall {
                            to { transform: translateY(${window.innerHeight + 50}px); }
                        }
                        @keyframes float {
                            from { transform: translateX(-100px); }
                            to { transform: translateX(${window.innerWidth + 100}px); }
                        }
                    `;
                    document.head.appendChild(style);
                </script>
            </body>
            </html>
      HTML
    end

    def retro_arcade_html
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Retro Arcade</title>
            <style>
                @import url('https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap');
                body { margin: 0; padding: 0; background: #000; color: #00ff00; font-family: 'Press Start 2P', monospace; height: 100vh; overflow: hidden; }
                .arcade-machine { width: 100%; height: 100%; background: linear-gradient(45deg, #1a1a1a, #333); display: flex; flex-direction: column; align-items: center; justify-content: center; }
                .screen { width: 80%; height: 70%; background: #000; border: 10px solid #444; border-radius: 20px; position: relative; overflow: hidden; display: flex; flex-direction: column; align-items: center; justify-content: center; }
                .pixel { width: 20px; height: 20px; background: #00ff00; position: absolute; animation: blink 2s infinite; }
                @keyframes blink { 0%, 50% { opacity: 1; } 51%, 100% { opacity: 0.3; } }
                .score { position: absolute; top: 20px; left: 20px; font-size: 16px; }
                .title { font-size: 24px; margin-bottom: 20px; text-align: center; animation: glow 2s infinite alternate; }
                @keyframes glow { from { text-shadow: 0 0 5px #00ff00; } to { text-shadow: 0 0 20px #00ff00, 0 0 30px #00ff00; } }
                .controls { margin-top: 20px; }
                .btn { background: #444; color: #00ff00; border: 2px solid #00ff00; padding: 10px 20px; margin: 0 10px; cursor: pointer; font-family: inherit; font-size: 12px; }
                .btn:hover { background: #00ff00; color: #000; }
            </style>
        </head>
        <body>
            <div class="arcade-machine">
                <div class="screen">
                    <div class="score">SCORE: <span id="score">0000</span></div>
                    <div class="title">RETRO ARCADE</div>
                    <div id="game-area" style="position: relative; width: 100%; height: 100%;"></div>
                </div>
                <div class="controls">
                    <button class="btn" onclick="startGame()">START</button>
                    <button class="btn" onclick="addPixel()">ADD PIXEL</button>
                    <button class="btn" onclick="clearScreen()">CLEAR</button>
                </div>
            </div>
            <script>
                let score = 0;
                let gameRunning = false;
        #{'        '}
                function updateScore() {
                    document.getElementById('score').textContent = score.toString().padStart(4, '0');
                }
        #{'        '}
                function addPixel() {
                    const gameArea = document.getElementById('game-area');
                    const pixel = document.createElement('div');
                    pixel.className = 'pixel';
                    pixel.style.left = Math.random() * (gameArea.offsetWidth - 20) + 'px';
                    pixel.style.top = Math.random() * (gameArea.offsetHeight - 20) + 'px';
                    pixel.style.background = `hsl(${Math.random() * 360}, 100%, 50%)`;
                    pixel.onclick = () => {
                        pixel.remove();
                        score += 10;
                        updateScore();
                    };
                    gameArea.appendChild(pixel);
                }
        #{'        '}
                function startGame() {
                    if(gameRunning) return;
                    gameRunning = true;
                    score = 0;
                    updateScore();
        #{'            '}
                    const interval = setInterval(() => {
                        addPixel();
                        if(document.querySelectorAll('.pixel').length > 20) {
                            clearInterval(interval);
                            gameRunning = false;
                        }
                    }, 1000);
                }
        #{'        '}
                function clearScreen() {
                    document.getElementById('game-area').innerHTML = '';
                    score = 0;
                    updateScore();
                    gameRunning = false;
                }
        #{'        '}
                updateScore();
            </script>
        </body>
        </html>
      HTML
    end

    def meditation_space_html
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Meditation Space</title>
            <style>
                body { margin: 0; padding: 0; background: radial-gradient(circle, #2c1810 0%, #1a0f0a 100%); color: #f4e4bc; font-family: 'Georgia', serif; height: 100vh; overflow: hidden; }
                .meditation-space { display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; text-align: center; }
                .breathing-circle { width: 200px; height: 200px; border: 3px solid #d4af37; border-radius: 50%; margin: 30px auto; animation: breathe 8s infinite; }
                @keyframes breathe { 0%, 100% { transform: scale(1); opacity: 0.7; } 50% { transform: scale(1.3); opacity: 1; } }
                .lotus { font-size: 60px; margin: 20px; animation: float 6s ease-in-out infinite; }
                @keyframes float { 0%, 100% { transform: translateY(0px); } 50% { transform: translateY(-10px); } }
                .mantra { font-size: 24px; margin: 20px 0; opacity: 0.8; font-style: italic; }
                .timer { font-size: 18px; margin: 10px; }
                .controls { margin-top: 30px; }
                .zen-btn { background: transparent; color: #d4af37; border: 2px solid #d4af37; padding: 12px 24px; margin: 0 10px; border-radius: 25px; cursor: pointer; font-family: inherit; transition: all 0.3s; }
                .zen-btn:hover { background: #d4af37; color: #1a0f0a; }
                .sound-indicator { position: absolute; top: 20px; right: 20px; opacity: 0.6; }
            </style>
        </head>
        <body>
            <div class="meditation-space">
                <div class="lotus">🪷</div>
                <h1 style="margin: 10px 0; font-size: 28px;">Meditation & Mindfulness</h1>
                <div class="mantra" id="mantra">"Breathe in peace, breathe out stress"</div>
                <div class="breathing-circle"></div>
                <div class="timer">Session: <span id="timer">00:00</span></div>
                <div class="controls">
                    <button class="zen-btn" onclick="startMeditation()">Start Session</button>
                    <button class="zen-btn" onclick="changeMantra()">Change Mantra</button>
                    <button class="zen-btn" onclick="toggleSounds()">Toggle Sounds</button>
                </div>
                <div class="sound-indicator">🔔 Meditation Bell</div>
            </div>
            <script>
                let sessionRunning = false;
                let sessionTime = 0;
                let sessionInterval;
                let currentMantra = 0;
        #{'        '}
                const mantras = [
                    "Breathe in peace, breathe out stress",
                    "I am calm and centered",
                    "This moment is perfect as it is",
                    "I release what no longer serves me",
                    "I am present and aware",
                    "Peace flows through my entire being"
                ];
        #{'        '}
                function startMeditation() {
                    if (sessionRunning) {
                        clearInterval(sessionInterval);
                        sessionRunning = false;
                        sessionTime = 0;
                        document.getElementById('timer').textContent = '00:00';
                        event.target.textContent = 'Start Session';
                        return;
                    }
        #{'            '}
                    sessionRunning = true;
                    event.target.textContent = 'End Session';
                    sessionInterval = setInterval(() => {
                        sessionTime++;
                        const minutes = Math.floor(sessionTime / 60).toString().padStart(2, '0');
                        const seconds = (sessionTime % 60).toString().padStart(2, '0');
                        document.getElementById('timer').textContent = `${minutes}:${seconds}`;
                    }, 1000);
                }
        #{'        '}
                function changeMantra() {
                    currentMantra = (currentMantra + 1) % mantras.length;
                    document.getElementById('mantra').textContent = `"${mantras[currentMantra]}"`;
                }
        #{'        '}
                function toggleSounds() {
                    const indicator = document.querySelector('.sound-indicator');
                    if (indicator.style.opacity === '0') {
                        indicator.style.opacity = '0.6';
                        indicator.textContent = '🔔 Meditation Bell';
                    } else {
                        indicator.style.opacity = '0';
                        indicator.textContent = '🔕 Sounds Off';
                    }
                }
        #{'        '}
                // Add some ambient stars
                function createStars() {
                    for (let i = 0; i < 30; i++) {
                        const star = document.createElement('div');
                        star.style.position = 'absolute';
                        star.style.width = '2px';
                        star.style.height = '2px';
                        star.style.background = '#d4af37';
                        star.style.borderRadius = '50%';
                        star.style.left = Math.random() * 100 + '%';
                        star.style.top = Math.random() * 100 + '%';
                        star.style.animation = `twinkle ${2 + Math.random() * 3}s infinite`;
                        document.body.appendChild(star);
                    }
                }
        #{'        '}
                const style = document.createElement('style');
                style.textContent = `
                    @keyframes twinkle {
                        0%, 100% { opacity: 0.3; }
                        50% { opacity: 1; }
                    }
                `;
                document.head.appendChild(style);
                createStars();
            </script>
        </body>
        </html>
      HTML
    end
  end
end
